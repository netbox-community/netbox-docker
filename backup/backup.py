#!/usr/bin/env python3

import os
import tarfile
import subprocess
from ftplib import FTP
from dotenv import load_dotenv
from datetime import datetime
from pathlib import Path
import sys


# --------------------------------------------------
# Load environment variables
# --------------------------------------------------
ENV_FILE = os.getenv("BACKUP_ENV", "backup.env")
load_dotenv(ENV_FILE)


def required(var_name: str) -> str:
    value = os.getenv(var_name)
    if not value:
        print(f"[ERROR] Missing required environment variable: {var_name}")
        sys.exit(1)
    return value


# --------------------------------------------------
# Required configuration
# --------------------------------------------------
FTP_SERVER = os.getenv("FTP_SERVER")
FTP_USER = os.getenv("FTP_USER")
FTP_PASSWORD = os.getenv("FTP_PASSWORD")
FTP_DIR = os.getenv("FTP_DIR", "/")

PG_USER = required("PG_USER")
PG_PASSWORD = required("PG_PASSWORD")
PG_DB = required("PG_DB")
PG_CONTAINER = required("PG_CONTAINER")

BACKUP_DIR = required("BACKUP_DIR")
NETBOX_VOLUME = required("NETBOX_VOLUME")
REPORTS_VOLUME = required("REPORTS_VOLUME")

# --------------------------------------------------
# Prepare paths & filenames
# --------------------------------------------------
DATE = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
Path(BACKUP_DIR).mkdir(parents=True, exist_ok=True)

NETBOX_BACKUP_FILE = f"{BACKUP_DIR}/netbox_media_{DATE}.tar.gz"
REPORTS_BACKUP_FILE = f"{BACKUP_DIR}/netbox_reports_{DATE}.tar.gz"
POSTGRES_BACKUP_FILE = f"{BACKUP_DIR}/postgres_{DATE}.sql.gz"


# --------------------------------------------------
# Helper functions
# --------------------------------------------------
def create_tar_gz(source: str, destination: str):
    print(f"[INFO] Creating archive: {destination}")
    with tarfile.open(destination, "w:gz") as tar:
        tar.add(source, arcname=os.path.basename(source))


def backup_postgres():
    print("[INFO] Backing up PostgreSQL database...")
    command = (
        f"docker exec {PG_CONTAINER} "
        f"pg_dump -U {PG_USER} {PG_DB} | gzip"
    )

    with open(POSTGRES_BACKUP_FILE, "wb") as f:
        subprocess.run(
            command,
            shell=True,
            check=True,
            env={**os.environ, "PGPASSWORD": PG_PASSWORD},
            stdout=f,
        )


def upload_to_ftp(local_file: str):
    if not FTP_SERVER:
        print("[INFO] FTP upload skipped (FTP_SERVER not set)")
        return

    print(f"[INFO] Uploading {os.path.basename(local_file)} to FTP...")
    with FTP(FTP_SERVER) as ftp:
        ftp.login(user=FTP_USER, passwd=FTP_PASSWORD)
        ftp.cwd(FTP_DIR)
        with open(local_file, "rb") as f:
            ftp.storbinary(f"STOR {os.path.basename(local_file)}", f)


# --------------------------------------------------
# Main execution
# --------------------------------------------------
try:
    print("[INFO] Starting NetBox backup process")

    create_tar_gz(NETBOX_VOLUME, NETBOX_BACKUP_FILE)
    create_tar_gz(REPORTS_VOLUME, REPORTS_BACKUP_FILE)
    backup_postgres()

    upload_to_ftp(NETBOX_BACKUP_FILE)
    upload_to_ftp(REPORTS_BACKUP_FILE)
    upload_to_ftp(POSTGRES_BACKUP_FILE)

    print("[INFO] Backup completed successfully")

finally:
    print("[INFO] Cleaning up local backup files")
    for file in [
        NETBOX_BACKUP_FILE,
        REPORTS_BACKUP_FILE,
        POSTGRES_BACKUP_FILE,
    ]:
        if os.path.exists(file):
            os.remove(file)
