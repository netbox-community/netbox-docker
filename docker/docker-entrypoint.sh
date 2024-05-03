#!/bin/bash
# Runs on every start of the NetBox Docker container

# Stop when an error occures
set -e

# Allows NetBox to be run as non-root users
umask 002

# Load correct Python3 env
# shellcheck disable=SC1091
source /opt/netbox/venv/bin/activate

# Try to connect to the DB
DB_WAIT_TIMEOUT=${DB_WAIT_TIMEOUT-3}
MAX_DB_WAIT_TIME=${MAX_DB_WAIT_TIME-30}
CUR_DB_WAIT_TIME=0
while [ "${CUR_DB_WAIT_TIME}" -lt "${MAX_DB_WAIT_TIME}" ]; do
  # Read and truncate connection error tracebacks to last line by default
  exec {psfd}< <(./manage.py showmigrations 2>&1)
  read -rd '' DB_ERR <&$psfd || :
  exec {psfd}<&-
  wait $! && break
  if [ -n "$DB_WAIT_DEBUG" ]; then
    echo "$DB_ERR"
  else
    readarray -tn 0 DB_ERR_LINES <<<"$DB_ERR"
    echo "${DB_ERR_LINES[@]: -1}"
    echo "[ Use DB_WAIT_DEBUG=1 in netbox.env to print full traceback for errors here ]"
  fi
  echo "⏳ Waiting on DB... (${CUR_DB_WAIT_TIME}s / ${MAX_DB_WAIT_TIME}s)"
  sleep "${DB_WAIT_TIMEOUT}"
  CUR_DB_WAIT_TIME=$((CUR_DB_WAIT_TIME + DB_WAIT_TIMEOUT))
done
if [ "${CUR_DB_WAIT_TIME}" -ge "${MAX_DB_WAIT_TIME}" ]; then
  echo "❌ Waited ${MAX_DB_WAIT_TIME}s or more for the DB to become ready."
  exit 1
fi
# Check if update is needed
if ! ./manage.py migrate --check >/dev/null 2>&1; then
  echo "⚙️ Applying database migrations"
  ./manage.py migrate --no-input
  echo "⚙️ Running trace_paths"
  ./manage.py trace_paths --no-input
  echo "⚙️ Removing stale content types"
  ./manage.py remove_stale_contenttypes --no-input
  echo "⚙️ Removing expired user sessions"
  ./manage.py clearsessions
  echo "⚙️ Building search index (lazy)"
  ./manage.py reindex --lazy
fi

# Create Superuser if required
if [ "$SKIP_SUPERUSER" == "true" ]; then
  echo "↩️ Skip creating the superuser"
else
  if [ -z ${SUPERUSER_NAME+x} ]; then
    SUPERUSER_NAME='admin'
  fi
  if [ -z ${SUPERUSER_EMAIL+x} ]; then
    SUPERUSER_EMAIL='admin@example.com'
  fi
  if [ -f "/run/secrets/superuser_password" ]; then
    SUPERUSER_PASSWORD="$(</run/secrets/superuser_password)"
  elif [ -z ${SUPERUSER_PASSWORD+x} ]; then
    SUPERUSER_PASSWORD='admin'
  fi
  if [ -f "/run/secrets/superuser_api_token" ]; then
    SUPERUSER_API_TOKEN="$(</run/secrets/superuser_api_token)"
  elif [ -z ${SUPERUSER_API_TOKEN+x} ]; then
    SUPERUSER_API_TOKEN='0123456789abcdef0123456789abcdef01234567'
  fi

  ./manage.py shell --interface python <<END
from django.contrib.auth.models import User
from users.models import Token
if not User.objects.filter(username='${SUPERUSER_NAME}'):
    u=User.objects.create_superuser('${SUPERUSER_NAME}', '${SUPERUSER_EMAIL}', '${SUPERUSER_PASSWORD}')
    Token.objects.create(user=u, key='${SUPERUSER_API_TOKEN}')
END

  echo "💡 Superuser Username: ${SUPERUSER_NAME}, E-Mail: ${SUPERUSER_EMAIL}"
fi

## Update superuser password and API Token if SUPERUSER_PASSWORD_OVERWRITE is true
## Doc
## https://docs.djangoproject.com/en/5.0/ref/models/querysets/#delete
if [ "$SUPERUSER_PASSWORD_OVERWRITE" == "true" ]; then
echo "will overwrite superuser password and api token for Superuser Username: ${SUPERUSER_NAME}"
  ./manage.py shell --interface python <<END
from django.contrib.auth.models import User
from users.models import Token
if User.objects.filter(username='${SUPERUSER_NAME}'):
    u=User.objects.get(username='${SUPERUSER_NAME}')
    u.set_password('${SUPERUSER_PASSWORD}')
    u.save()
    Token.objects.filter(user=u).delete()
    Token.objects.create(user=u, key='${SUPERUSER_API_TOKEN}')
END

  echo "💡 Superuser password and API Token updated"
fi


./manage.py shell --interface python <<END
from users.models import Token
try:
    old_default_token = Token.objects.get(key="0123456789abcdef0123456789abcdef01234567")
    if old_default_token:
        print("⚠️ Warning: You have the old default admin token in your database. This token is widely known; please remove it.")
except Token.DoesNotExist:
    pass
END

echo "✅ Initialisation is done."

# Launch whatever is passed by docker
# (i.e. the RUN instruction in the Dockerfile)
exec "$@"
