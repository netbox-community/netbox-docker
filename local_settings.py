from os import environ
from urllib.parse import quote

REDIS_URL = f"redis://:{quote(environ.get('REDIS_PASSWORD', ''))}@{environ.get('REDIS_HOST', 'localhost')}:{environ.get('REDIS_PORT', '6379')}/{environ.get('REDIS_DATABASE', '1')}"
