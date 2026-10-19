
import io
import os
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

# Quyền đọc file và thư mục trên Google Drive
SCOPES = ["https://www.googleapis.com/auth/drive.readonly"]
# Đường dẫn từ file Python đến thư mục gốc dự án
PROJECT_ROOT = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "..")
)
SERVICE_ACCOUNT_PATH = os.path.join(
    PROJECT_ROOT, "service_account.json"
)

def authenticate_google_drive():
    """Xác thực Google Drive bằng Service Account."""

    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_PATH,
        scopes=SCOPES,
    )
    return build("drive", "v3", credentials=creds)


def list_drive_files(folder_id):
    """Liệt kê file trực tiếp trong thư mục Google Drive."""
    service = authenticate_google_drive()
    query = f"'{folder_id}' in parents and trashed = false"
    files_found = []
    page_token = None
    while True:
        response = service.files().list(
            q=query,
            pageSize=1000,
            pageToken=page_token,
            fields=(
                "nextPageToken, files(id, name, mimeType, "
                "modifiedTime, size)"
            ),
            supportsAllDrives=True,
            includeItemsFromAllDrives=True,
        ).execute()
        files_found.extend(response.get("files", []))
        page_token = response.get("nextPageToken")
        if not page_token:
            break

    return files_found

def list_files_in_folder(folder_id):
    return list_drive_files(folder_id)

def download_file_as_bytes(file_id):
    service = authenticate_google_drive()
    request = service.files().get_media(fileId=file_id)
    file_buffer = io.BytesIO()
    downloader = MediaIoBaseDownload(file_buffer, request)
    done = False
    while not done:
        _, done = downloader.next_chunk()
    return file_buffer.getvalue()

if __name__ == "__main__":
    folder_id = input("Enter your Google Drive Folder ID: ").strip()

    try:
        files_found = list_drive_files(folder_id)

        if not files_found:
            print("No files found. Check the folder ID and access permissions.")
        else:
            print(f"\nFound {len(files_found)} item(s):\n")

            for file in files_found:
                print(
                    f"Name: {file['name']}\n"
                    f"ID: {file['id']}\n"
                    f"Type: {file['mimeType']}\n"
                    f"Size: {file.get('size', 'N/A')} bytes\n"
                    f"{'-' * 40}"
                )

    except Exception as error:
        print(f"Google Drive connection failed: {error}")
