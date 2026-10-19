import os
import re
import unicodedata
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
 
load_dotenv()
 
META_COLS = ["_source_file", "_source_platform", "_ingested_at", "_batch_id"]
_engine = None
 
def get_engine():
    global _engine
    if _engine is None:
        url = (f"postgresql+psycopg2://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}"
               f"@{os.getenv('DB_HOST', 'localhost')}:{os.getenv('DB_PORT', '5432')}"
               f"/{os.getenv('DB_NAME')}")
        _engine = create_engine(url, pool_pre_ping=True)
    return _engine
 
def _q(identifier):
    return '"' + str(identifier).replace('"', '""') + '"'
 
# chuẩn hóa tên cột
def clean_column_name(name):
    s = str(name).replace("đ", "d").replace("Đ", "D")
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    s = re.sub(r"[^0-9a-zA-Z]+", "_", s).strip("_").lower()
    return s or "col"
def normalize_columns(df):
    seen, new_cols = {}, []
    for c in df.columns:
        base = clean_column_name(c)
        if base in META_COLS:
            base = f"src_{base.lstrip('_')}"
        n = seen.get(base, 0)
        seen[base] = n + 1
        new_cols.append(base if n == 0 else f"{base}_{n + 1}")
    df = df.copy()
    df.columns = new_cols
    return df
 
# metadata
def add_metadata(df, source_file, source_platform, batch_id):
    df = normalize_columns(df)
    df["_source_file"] = source_file
    df["_source_platform"] = source_platform
    df["_batch_id"] = str(batch_id)
    return df
 
# tạo / mở rộng bảng
def ensure_table(engine, table, columns, schema="raw"):
    data_cols = [c for c in columns if c not in META_COLS]
    if not data_cols:
        raise ValueError("File không có cột dữ liệu nào")
    cols_ddl = ", ".join(f"{_q(c)} TEXT" for c in data_cols)
    with engine.begin() as conn:
        conn.execute(text(
            f"CREATE TABLE IF NOT EXISTS {schema}.{_q(table)} ({cols_ddl}, "
            "_source_file TEXT, _source_platform TEXT, "
            "_ingested_at TIMESTAMP DEFAULT NOW(), _batch_id UUID)"
        ))
        existing = {r[0] for r in conn.execute(text(
            "SELECT column_name FROM information_schema.columns "
            "WHERE table_schema = :s AND table_name = :t"), dict(s=schema, t=table))}
        for c in data_cols:
            if c not in existing:
                conn.execute(text(f"ALTER TABLE {schema}.{_q(table)} ADD COLUMN {_q(c)} TEXT"))
 
# Load to Bronze
def load_to_bronze(df, table, engine=None, schema="raw", chunksize=5000, if_exists="append"):
    engine = engine or get_engine()
    df = df.astype(object).where(pd.notna(df), None)
    ensure_table(engine, table, list(df.columns), schema)
    if if_exists == "replace":
        with engine.begin() as conn:
            conn.execute(text(f"TRUNCATE TABLE {schema}.{_q(table)}"))
    df.to_sql(table, engine, schema=schema, if_exists="append", index=False,
              chunksize=chunksize, method="multi")
    return len(df)
 
#log
def log_ingest(engine, batch_id, source_name, source_file, source_platform,
               rows_loaded, status, duration_sec, error_message=None,
               file_id=None, file_modified_time=None):
    with engine.begin() as conn:
        conn.execute(text(
            "INSERT INTO raw.ingest_log (batch_id, source_name, source_file, source_platform, "
            "file_id, file_modified_time, rows_loaded, status, error_message, duration_sec) "
            "VALUES (:bid, :sn, :sf, :sp, :fid, :fmt, :rl, :st, :err, :dur)"),
            dict(bid=str(batch_id), sn=source_name, sf=source_file, sp=source_platform,
                 fid=file_id, fmt=file_modified_time, rl=rows_loaded, st=status,
                 err=error_message, dur=round(duration_sec, 2)))
 
def already_loaded(engine, source_name, file_id, file_modified_time):
    """True nếu đúng phiên bản file này đã nạp thành công trước đó."""
    with engine.connect() as conn:
        row = conn.execute(text(
            "SELECT 1 FROM raw.ingest_log WHERE source_name = :sn AND file_id = :fid "
            "AND file_modified_time = :fmt AND status = 'SUCCESS' LIMIT 1"),
            dict(sn=source_name, fid=file_id, fmt=file_modified_time)).first()
    return row is not None