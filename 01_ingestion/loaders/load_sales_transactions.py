
import os
import sys
import time
import uuid

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from connectors.gdrive_connector import (
    list_files_in_folder,
    download_file_as_bytes
)
from utils.file_parser import parse_file
from utils.db_utils import (
    add_metadata,
    load_to_bronze,
    get_engine,
    already_loaded,
    log_ingest
)

FOLDER_ID = '1DxPEHsw8n8_jv6KKSgEdAoEpbkqSWGaa'
TABLE_NAME = 'sales_transactions'
PLATFORM = 'google_drive'


def run():
    batch_id = str(uuid.uuid4())
    engine = get_engine()

    files = list_files_in_folder(FOLDER_ID)
    print(f'Tim thay {len(files)} file(s) trong folder')

    total_loaded = 0

    for f in files:
        if not f['name'].startswith('SRC01'):
            continue

        file_id = f['id']
        file_name = f['name']
        modified_time = f.get('modifiedTime')
        file_start = time.time()

        print(f'\nFILE: {file_name}')

        try:
            # Bo qua neu dung phien ban file da duoc nap thanh cong
            if already_loaded(
                engine,
                TABLE_NAME,
                file_id,
                modified_time
            ):
                print(
                    f'  BO QUA: {file_name} '
                    '- phien ban nay da duoc nap'
                )
                continue

            raw_bytes = download_file_as_bytes(file_id)
            df = parse_file(raw_bytes, file_name)

            df = add_metadata(
                df,
                file_name,
                PLATFORM,
                batch_id
            )

            rows = load_to_bronze(
                df,
                TABLE_NAME,
                engine=engine,
                schema='raw',
                if_exists='append'
            )

            log_ingest(
                engine=engine,
                batch_id=batch_id,
                source_name=TABLE_NAME,
                source_file=file_name,
                source_platform=PLATFORM,
                rows_loaded=rows,
                status='SUCCESS',
                duration_sec=time.time() - file_start,
                file_id=file_id,
                file_modified_time=modified_time
            )

            total_loaded += rows
            print(f'  OK: {rows} dong da nap')

        except Exception as e:
            print(f'  LOI: {file_name} - {e}')

            try:
                log_ingest(
                    engine=engine,
                    batch_id=batch_id,
                    source_name=TABLE_NAME,
                    source_file=file_name,
                    source_platform=PLATFORM,
                    rows_loaded=0,
                    status='FAILED',
                    duration_sec=time.time() - file_start,
                    error_message=str(e),
                    file_id=file_id,
                    file_modified_time=modified_time
                )
            except Exception as log_error:
                print(f'  LOI GHI LOG: {log_error}')

    print(f'\nTong cong: {total_loaded} dong da load')


if __name__ == '__main__':
    run()
