#!/bin/bash
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# Make all environment variables to be used with Docker secrets

file_env 'SUPERUSER_NAME'
file_env 'SUPERUSER_EMAIL'
file_env 'SUPERUSER_PASSWORD'
file_env 'SUPERUSER_API_TOKEN'
file_env 'ALLOWED_HOSTS'
file_env 'DB_NAME'
file_env 'DB_USER'
file_env 'DB_PASSWORD'
file_env 'DB_HOST'
file_env 'SECRET_KEY'
file_env 'EMAIL_SERVER'
file_env 'EMAIL_PORT'
file_env 'EMAIL_USERNAME'
file_env 'EMAIL_PASSWORD'
file_env 'EMAIL_TIMEOUT'
file_env 'EMAIL_FROM'
file_env 'NETBOX_USERNAME'
file_env 'NETBOX_PASSWORD'

# wait shortly and then run db migrations (retry on error)
while ! ./manage.py migrate 2>&1; do
  echo "⏳ Waiting on DB..."
  sleep 3
done

# create superuser silently
if [[ -z ${SUPERUSER_NAME} ]]; then
  SUPERUSER_NAME='admin'
fi
if [[ -z ${SUPERUSER_EMAIL} ]]; then
  SUPERUSER_EMAIL='admin@example.com'
fi
if [[ -z ${SUPERUSER_PASSWORD} ]]; then
  SUPERUSER_PASSWORD='admin'
fi
if [[ -z ${SUPERUSER_API_TOKEN} ]]; then
  SUPERUSER_API_TOKEN='0123456789abcdef0123456789abcdef01234567'
fi

echo "💡 Username: ${SUPERUSER_NAME}, E-Mail: ${SUPERUSER_EMAIL}, Password: ${SUPERUSER_PASSWORD}, Token: ${SUPERUSER_API_TOKEN}"

./manage.py shell --plain << END
from django.contrib.auth.models import User
from users.models import Token
if not User.objects.filter(username='${SUPERUSER_NAME}'):
    u=User.objects.create_superuser('${SUPERUSER_NAME}', '${SUPERUSER_EMAIL}', '${SUPERUSER_PASSWORD}')
    Token.objects.create(user=u, key='${SUPERUSER_API_TOKEN}')
END

# copy static files
./manage.py collectstatic --no-input

echo "✅ Initialisation is done."

# launch whatever is passed by docker via RUN
exec ${@}
