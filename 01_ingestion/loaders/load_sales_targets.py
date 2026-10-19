import os
import re
import sys
import time
import unicodedata
import uuid
 
import pandas as pd
 
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
 
from sqlalchemy import text
 
from connectors.gdrive_connector import download_file_as_bytes, list_files_in_folder
from utils.db_utils import add_metadata, ensure_table, get_engine, log_ingest
from utils.file_parser import list_sheets, parse_file
 
FOLDER_ID = '1DxPEHsw8n8_jv6KKSgEdAoEpbkqSWGaa'
FILE_PREFIX = "SRC02"
DATA_TABLE = "sales_targets_raw"
PLATFORM = "google_drive"
 
DDL = """
CREATE TABLE IF NOT EXISTS raw.sales_target_files (
    target_file_id      BIGSERIAL PRIMARY KEY,
    batch_id            UUID NOT NULL,
    source_file         TEXT NOT NULL,
    drive_file_id       TEXT,
    file_modified_time  TEXT,
    sheet_name          TEXT,
    version_label       TEXT NOT NULL,
    rows_loaded         INT,
    _source_platform    TEXT,
    loaded_at           TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_sales_target_files_lookup
    ON raw.sales_target_files (drive_file_id, file_modified_time, sheet_name);
 
CREATE TABLE IF NOT EXISTS raw.sales_targets_raw (
    target_row_id     BIGSERIAL PRIMARY KEY,
    target_file_id    BIGINT NOT NULL REFERENCES raw.sales_target_files (target_file_id),
    source_row        INT,
    month_col         TEXT,     
    _source_file      TEXT,
    _source_platform  TEXT,
    _ingested_at      TIMESTAMP DEFAULT NOW(),
    _batch_id         UUID
);
"""

def _norm(value):
    s = str(value).replace("đ", "d").replace("Đ", "D")
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"\s+", " ", s).strip().lower()
 
 
def _col_key(name):
    return _norm(name).replace(" ", "_")
 
TOTAL_WORDS = {"tong", "tong cong", "total", "grand total"}
VERSION_RE = re.compile(r"(?:^|[^a-z0-9])(?:v|ver|version|phien ban)\s*(\d+)(?!\d)")
 
def version_label(sheet_name, file_name):
    """Tìm v1/v2... trong tên sheet trước, rồi đến tên file. Không thấy -> dùng tên sheet."""
    for source in (sheet_name, file_name):
        m = VERSION_RE.search(_norm(source))
        if m:
            return f"v{int(m.group(1))}"
    return str(sheet_name).strip()
 
def resolve_label(df, sheet_name, file_name):
    from_name = version_label(sheet_name, file_name)
    col = next((c for c in df.columns if _col_key(c) == "plan_version"), None)
    if col is not None:
        vals = df[col].dropna().map(_norm).unique()
        if len(vals) == 1 and vals[0]:
            if vals[0] != from_name.lower():
                print(f"Lưu ý: plan_version trong dữ liệu = '{vals[0]}' nhưng tên sheet gợi ý"
                      f"'{from_name}' -> dùng giá trị trong dữ liệu")
            return vals[0]
        print(f"CẢNH BÁO: cột plan_version có {len(vals)} giá trị khác nhau trong 1 sheet {list(vals)}")
    return from_name
 
def prepare_sheet(df):
    keys = {c: _col_key(c) for c in df.columns}
    month_src = next((c for c, k in keys.items() if k in ("month", "thang")), None)
    if month_src is None or not any(k.startswith("target") for k in keys.values()):
        return None
 
    df = df.copy()
    df["source_row"] = range(1, len(df) + 1)
 
    # bỏ cột Tổng và dòng TỔNG
    total_cols = [c for c, k in keys.items() if k.startswith(("tong", "total"))]
    df = df.drop(columns=total_cols)
    is_total = df.apply(lambda col: col.map(lambda v: pd.notna(v) and _norm(v) in TOTAL_WORDS)).any(axis=1)
    dropped = int(is_total.sum())
    df = df[~is_total].reset_index(drop=True)
 
    months = pd.to_numeric(df[month_src], errors="coerce")
    valid = months.between(1, 12)
    df["month_col"] = [f"T{int(m)}" if ok else None for m, ok in zip(months, valid)]
 
    emp_col = next((c for c in df.columns if _col_key(c) == "employee_id"), None)
    rev_col = next((c for c in df.columns if _col_key(c) == "target_revenue"), None)
    info = dict(
        rows=len(df), dropped_total_rows=dropped, total_cols=total_cols,
        bad_months=int((~valid).sum()),
        months=sorted({m for m in df["month_col"].dropna()}, key=lambda s: int(s[1:])),
        employees=int(df[emp_col].nunique()) if emp_col else None,
        revenue=float(pd.to_numeric(df[rev_col], errors="coerce").sum()) if rev_col else None,
    )
    return df, info
 

def ensure_target_tables(engine):
    # Chạy từng câu DDL riêng để tránh lỗi khi bảng đã tồn tại.
    statements = [
        """
        CREATE TABLE IF NOT EXISTS raw.sales_target_files (
            target_file_id BIGSERIAL PRIMARY KEY,
            batch_id UUID NOT NULL,
            source_file TEXT NOT NULL,
            drive_file_id TEXT,
            file_modified_time TEXT,
            sheet_name TEXT,
            version_label TEXT NOT NULL,
            rows_loaded INT,
            _source_platform TEXT,
            loaded_at TIMESTAMP DEFAULT NOW()
        )
        """,
        """
        CREATE INDEX IF NOT EXISTS ix_sales_target_files_lookup
        ON raw.sales_target_files
            (drive_file_id, file_modified_time, sheet_name)
        """,
        """
        CREATE TABLE IF NOT EXISTS raw.sales_targets_raw (
            target_row_id BIGSERIAL PRIMARY KEY,
            target_file_id BIGINT NOT NULL
                REFERENCES raw.sales_target_files (target_file_id),
            source_row INT,
            month_col TEXT,
            _source_file TEXT,
            _source_platform TEXT,
            _ingested_at TIMESTAMP DEFAULT NOW(),
            _batch_id UUID
        )
        """
    ]
    with engine.begin() as conn:
        conn.execute(text("CREATE SCHEMA IF NOT EXISTS raw"))
        for statement in statements:
            conn.execute(text(statement))
 
def sheet_already_loaded(engine, drive_file_id, modified, sheet):
    with engine.connect() as conn:
        row = conn.execute(text(
            "SELECT 1 FROM raw.sales_target_files WHERE drive_file_id = :i "
            "AND file_modified_time = :m AND sheet_name = :s LIMIT 1"),
            dict(i=drive_file_id, m=modified, s=sheet)).first()
    return row is not None
 
 
def insert_sheet(engine, f, sheet, label, df, batch_id):
    """Ghi 1 dòng vào sales_target_files + toàn bộ dữ liệu sheet, trong CÙNG 1 transaction."""
    df = add_metadata(df, f["name"], PLATFORM, batch_id)
    ensure_table(engine, DATA_TABLE, list(df.columns))           # tự thêm các cột của file
    df = df.astype(object).where(pd.notna(df), None)
 
    with engine.begin() as conn:
        fid = conn.execute(text(
            "INSERT INTO raw.sales_target_files (batch_id, source_file, drive_file_id, "
            "file_modified_time, sheet_name, version_label, rows_loaded, _source_platform) "
            "VALUES (:b, :sf, :di, :fm, :sh, :vl, :rl, :sp) RETURNING target_file_id"),
            dict(b=batch_id, sf=f["name"], di=f["id"], fm=f["modifiedTime"], sh=sheet, vl=label,
                 rl=len(df), sp=PLATFORM)).scalar()
        df["target_file_id"] = fid
        df.to_sql(DATA_TABLE, conn, schema="raw", if_exists="append", index=False,
                  chunksize=5000, method="multi")
    return len(df)
 
def run(force=False, dry_run=False):
    batch_id = str(uuid.uuid4())
    engine = None if dry_run else get_engine()
    if engine is not None:
        ensure_target_tables(engine)
 
    files = [f for f in list_files_in_folder(FOLDER_ID) if f["name"].startswith(FILE_PREFIX)]
    print(f"[{DATA_TABLE}] batch {batch_id[:8]} - {len(files)} file bắt đầu bằng '{FILE_PREFIX}'"
          + ("  (DRY-RUN: không ghi database)" if dry_run else ""))
 
    total = 0
    for f in files:
        start, loaded_sheets, file_rows = time.time(), 0, 0
        common = dict(batch_id=batch_id, source_name=DATA_TABLE, source_file=f["name"],
                      source_platform=PLATFORM, file_id=f["id"], file_modified_time=f["modifiedTime"])
        print(f"\n  FILE: {f['name']}")
        try:
            raw_bytes = download_file_as_bytes(f["id"])
            for sheet in list_sheets(raw_bytes, f["name"]):
                if engine is not None and not force and sheet_already_loaded(
                        engine, f["id"], f["modifiedTime"], sheet):
                    print(f"    SKIP sheet '{sheet}' (đã nạp đúng phiên bản này)")
                    continue
 
                df = parse_file(raw_bytes, f["name"], sheet_name=sheet, header="auto")
                result = prepare_sheet(df) if not df.empty else None
                if result is None:
                    print(f"    BỎ QUA sheet '{sheet}' (không phải sheet dữ liệu: thiếu cột month / target_*)")
                    continue
                df, info = result
                label = resolve_label(df, sheet, f["name"])
 
                print(f"Sheet '{sheet}' -> version_label = '{label}'")
                print(f"số dòng: {info['rows']}   (dòng TỔNG bỏ: {info['dropped_total_rows']}, "
                      f"cột Tổng bỏ: {info['total_cols']})")
                print(f"tháng có mặt: {info['months']}"
                      + (f"<-- {info['bad_months']} dòng có month không hợp lệ!" if info['bad_months'] else ""))
                if info["employees"] is not None:
                    print(f"số nhân viên: {info['employees']}")
                if info["revenue"] is not None:
                    print(f"tổng target_revenue: {info['revenue']:,.0f}")
 
                if dry_run:
                    print(df.head(4).to_string(max_colwidth=16))
                    continue
 
                rows = insert_sheet(engine, f, sheet, label, df, batch_id)
                file_rows += rows
                loaded_sheets += 1
                print(f"OK: {rows} dòng đã nạp")
 
            total += file_rows
            if not dry_run:
                log_ingest(engine, rows_loaded=file_rows,
                           status="SUCCESS" if loaded_sheets else "SKIPPED",
                           duration_sec=time.time() - start, **common)
        except Exception as e:
            print(f"    LỖI: {f['name']} — {e}")
            if not dry_run:
                log_ingest(engine, rows_loaded=0, status="FAILED",
                           duration_sec=time.time() - start, error_message=str(e), **common)
 
    print(f"\nTổng cộng: {total} dòng đã load")
    return total
 
if __name__ == "__main__":
    run(force="--force" in sys.argv, dry_run="--dry-run" in sys.argv)