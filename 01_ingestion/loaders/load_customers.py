
import uuid
import time

from connectors.gdrive_connector import (
    list_files_in_folder,
    download_file_as_bytes,
)
from utils.file_parser import parse_file
from utils.db_utils import (
    add_metadata,
    load_to_bronze,
    get_engine,
    already_loaded,
    log_ingest,
)

FOLDER_ID = '1DxPEHsw8n8_jv6KKSgEdAoEpbkqSWGaa'
TABLE_NAME = 'customer_master'


def run():
    batch_id = str(uuid.uuid4())
    start = time.time()
    engine = get_engine()

    files = list_files_in_folder(FOLDER_ID)
    print(f'Tìm thấy {len(files)} file(s) trong folder')

    total_loaded = 0

    for f in files:
        if not f['name'].startswith('SRC03'):
            continue

        file_id = f['id']
        modified_time = f.get('modifiedTime')

        try:
            # Bỏ qua nếu đúng phiên bản file đã nạp thành công
            if already_loaded(
                engine,
                TABLE_NAME,
                file_id,
                modified_time,
            ):
                print(f'  BỎ QUA: {f["name"]} — phiên bản đã được nạp')
                continue

            raw_bytes = download_file_as_bytes(file_id)
            df = parse_file(raw_bytes, f['name'])
            df = add_metadata(
                df,
                f['name'],
                'google_drive',
                batch_id,
            )

            rows = load_to_bronze(
                df,
                TABLE_NAME,
                if_exists='append',
            )
            total_loaded += rows

            log_ingest(
                engine=engine,
                batch_id=batch_id,
                source_name=TABLE_NAME,
                source_file=f['name'],
                source_platform='google_drive',
                rows_loaded=rows,
                status='SUCCESS',
                duration_sec=time.time() - start,
                file_id=file_id,
                file_modified_time=modified_time,
            )

            print(f'  OK: {f["name"]} — {rows} dòng')

        except Exception as e:
            print(f'  LỖI: {f["name"]} — {e}')

            try:
                log_ingest(
                    engine=engine,
                    batch_id=batch_id,
                    source_name=TABLE_NAME,
                    source_file=f['name'],
                    source_platform='google_drive',
                    rows_loaded=0,
                    status='FAILED',
                    duration_sec=time.time() - start,
                    error_message=str(e),
                    file_id=file_id,
                    file_modified_time=modified_time,
                )
            except Exception as log_error:
                print(f'  LỖI GHI LOG: {log_error}')

    print(f'Tổng cộng: {total_loaded} dòng đã load')


if __name__ == '__main__':
    run()
