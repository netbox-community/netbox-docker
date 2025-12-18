# NetBox Docker Backup Script

This script provides a simple and flexible backup solution for NetBox Docker deployments.

## Features

- NetBox media backup
- Reports backup
- PostgreSQL database backup
- Optional FTP upload
- Environment-based configuration

## Requirements

- Docker
- Python 3.8+
- NetBox Docker deployment

## Usage

```bash
cp backup.env.example backup.env
python3 backup.py
