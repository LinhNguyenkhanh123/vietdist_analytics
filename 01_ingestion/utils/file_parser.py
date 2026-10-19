import csv
import io
import sys
import zipfile
import pandas as pd
 
CSV_ENCODINGS = ("utf-8-sig", "utf-8", "cp1258", "cp1252", "latin1")
ZIP_MAGIC = b"PK\x03\x04" 
OLE_MAGIC = b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1"
 
def _drop_empty(df):
    df = df.dropna(how="all")
    junk = [c for c in df.columns if str(c).startswith("Unnamed:") and df[c].isna().all()]
    return df.drop(columns=junk).reset_index(drop=True)
 
def excel_serial_to_datetime(series):
    return pd.to_datetime(pd.to_numeric(series, errors="coerce"), unit="D", origin="1899-12-30")
 
# 1. CSV
def parse_csv(raw_bytes, header=0, **kwargs):
    last_err = None
    for enc in CSV_ENCODINGS:
        try:
            text_sample = raw_bytes[:8192].decode(enc, errors="strict")
        except UnicodeDecodeError as e:
            last_err = e
            continue
 
        if "sep" not in kwargs and "delimiter" not in kwargs:
            try:
                kwargs["sep"] = csv.Sniffer().sniff(text_sample, delimiters=",;\t|").delimiter
            except csv.Error:
                kwargs["sep"] = ","
        try:
            df = pd.read_csv(io.BytesIO(raw_bytes), dtype=str, encoding=enc, header=header,
                             keep_default_na=False, na_values=[""], **kwargs)
        except UnicodeDecodeError as e:   # lỗi nằm ở phần sau 8KB đầu
            last_err = e
            continue
        df.attrs["encoding"] = enc
        return _drop_empty(df)
    raise ValueError(f"Không đọc được encoding của file CSV: {last_err}")
  
#2-4. Excel: XLSX, XLSM, XLSB
def _excel_engine(raw_bytes, file_name):
    if raw_bytes[:4] != ZIP_MAGIC:
        if raw_bytes[:8] == OLE_MAGIC:
            raise ValueError(f"{file_name}: là file .xls cũ hoặc đã đặt mật khẩu - "
                             "hãy lưu lại thành .xlsx hoặc bỏ mật khẩu")
        if raw_bytes[:200].lstrip().lower().startswith(b"<"):
            raise ValueError(f"{file_name}: nội dung là HTML, không phải Excel "
                             "(có thể tải lỗi hoặc đây là trang đăng nhập)")
        raise ValueError(f"{file_name}: không phải file Excel hợp lệ")
 
    with zipfile.ZipFile(io.BytesIO(raw_bytes)) as z:
        names = set(z.namelist())
    if "xl/workbook.bin" in names:
        engine = "pyxlsb"
    elif "xl/workbook.xml" in names:
        engine = "openpyxl"
    else:
        raise ValueError(f"{file_name}: file zip không có workbook Excel bên trong")
    if engine == "pyxlsb":
        try:
            import pyxlsb  # noqa: F401
        except ImportError:
            raise ImportError("Thiếu thư viện pyxlsb, hãy cài đặt bằng: pip install pyxlsb")
    return engine
 
def list_sheets(raw_bytes, file_name):
    engine = _excel_engine(raw_bytes, file_name)
    return pd.ExcelFile(io.BytesIO(raw_bytes), engine=engine).sheet_names
 
def detect_header_row(raw_bytes, file_name, sheet_name=0, max_scan=30):
    engine = _excel_engine(raw_bytes, file_name)
    preview = pd.read_excel(io.BytesIO(raw_bytes), sheet_name=sheet_name, header=None,
                            nrows=max_scan, dtype=str, engine=engine)
    counts = preview.notna().sum(axis=1)
    if counts.empty or counts.max() == 0:
        return 0
    threshold = 0.8 * counts.max()
    for idx, n in counts.items():
        if n >= threshold:
            return int(idx)
    return 0
 
def _parse_excel(raw_bytes, file_name, sheet_name=0, header=0, **kwargs):
    engine = _excel_engine(raw_bytes, file_name)
    ext = file_name.lower().rsplit(".", 1)[-1]
    if (engine == "pyxlsb") != (ext == "xlsb"):
        print(f"  [cảnh báo] {file_name}: đuôi file không khớp nội dung, dùng engine {engine}")
 
    if header == "auto":
        header = detect_header_row(raw_bytes, file_name, sheet_name)
        print(f"  [header] {file_name}: tiêu đề ở dòng {header + 1}")
 
    df = pd.read_excel(io.BytesIO(raw_bytes), sheet_name=sheet_name, header=header,
                       dtype=str, engine=engine, **kwargs)
    return _drop_empty(df)
 
def parse_xlsx(raw_bytes, file_name="file.xlsx", sheet_name=0, header=0, **kwargs):
    """XLSX - đọc bằng openpyxl."""
    return _parse_excel(raw_bytes, file_name, sheet_name, header, **kwargs)
 
def parse_xlsm(raw_bytes, file_name="file.xlsm", sheet_name=0, header=0, **kwargs):
    return _parse_excel(raw_bytes, file_name, sheet_name, header, **kwargs)
 
def parse_xlsb(raw_bytes, file_name="file.xlsb", sheet_name=0, header=0, **kwargs):
    return _parse_excel(raw_bytes, file_name, sheet_name, header, **kwargs)
 
def parse_all_sheets(raw_bytes, file_name, header=0, **kwargs):
    return {s: _parse_excel(raw_bytes, file_name, s, header, **kwargs)
            for s in list_sheets(raw_bytes, file_name)}
 
# Hàm điều phối
_PARSERS = {"csv": parse_csv, "txt": parse_csv,
            "xlsx": parse_xlsx, "xlsm": parse_xlsm, "xlsb": parse_xlsb}
def parse_file(raw_bytes, file_name, sheet_name=0, header=0, **kwargs):
    ext = file_name.lower().rsplit(".", 1)[-1] if "." in file_name else ""
    if ext not in _PARSERS:
        raise ValueError(f"Định dạng không hỗ trợ: .{ext} ({file_name}). "
                         "Hỗ trợ: csv, xlsx, xlsm, xlsb")
    if ext in ("csv", "txt"):
        return parse_csv(raw_bytes, header=0 if header == "auto" else header, **kwargs)
    return _PARSERS[ext](raw_bytes, file_name, sheet_name=sheet_name, header=header, **kwargs)
 
# Test
if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit("Cách dùng: python file_parser.py <đường_dẫn_file>")
    path = sys.argv[1]
    with open(path, "rb") as fh:
        data = fh.read()
    name = path.replace("\\", "/").split("/")[-1]
 
    if name.lower().endswith((".xlsx", ".xlsm", ".xlsb")):
        print("Các sheet:", list_sheets(data, name))
        for sheet in list_sheets(data, name):
            print(f"\n--- Sheet '{sheet}' (header tự dò) ---")
            d = parse_file(data, name, sheet_name=sheet, header="auto")
            print(d.shape)
            print(d.head(5).to_string())
    else:
        d = parse_file(data, name)
        print("Encoding:", d.attrs.get("encoding"), "| shape:", d.shape)
        print(d.head(5).to_string())