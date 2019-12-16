#!/bin/bash
set -e

# wait shortly and then run db migrations (retry on error)
while ! ./manage.py migrate 2>&1; do
  echo "⏳ Waiting on DB..."
  sleep 3
done

if [ "$SKIP_SUPERUSER" == "true" ]; then
  echo "↩️ Skip creating the superuser"
else
  if [ -z ${SUPERUSER_NAME+x} ]; then
    SUPERUSER_NAME='admin'
  fi
  if [ -z ${SUPERUSER_EMAIL+x} ]; then
    SUPERUSER_EMAIL='admin@example.com'
  fi
  if [ -z ${SUPERUSER_PASSWORD+x} ]; then
    if [ -f "/run/secrets/superuser_password" ]; then
      SUPERUSER_PASSWORD="$(< /run/secrets/superuser_password)"
    else
      SUPERUSER_PASSWORD='admin'
    fi
  fi
  if [ -z ${SUPERUSER_API_TOKEN+x} ]; then
    if [ -f "/run/secrets/superuser_api_token" ]; then
      SUPERUSER_API_TOKEN="$(< /run/secrets/superuser_api_token)"
    else
      SUPERUSER_API_TOKEN='0123456789abcdef0123456789abcdef01234567'
    fi
  fi

  ./manage.py shell --interface python << END
from django.contrib.auth.models import User
from users.models import Token
if not User.objects.filter(username='${SUPERUSER_NAME}'):
    u=User.objects.create_superuser('${SUPERUSER_NAME}', '${SUPERUSER_EMAIL}', '${SUPERUSER_PASSWORD}')
    Token.objects.create(user=u, key='${SUPERUSER_API_TOKEN}')
END

  echo "💡 Superuser Username: ${SUPERUSER_NAME}, E-Mail: ${SUPERUSER_EMAIL}"
fi

if [ "$SKIP_STARTUP_SCRIPTS" == "true" ]; then
  echo "↩️ Skipping startup scripts"
else
  echo "import runpy; runpy.run_path('../startup_scripts')" | ./manage.py shell --interface python
fi

# copy static files
./manage.py collectstatic --no-input

echo "✅ Initialisation is done."

# launch whatever is passed by docker
# (i.e. the RUN instruction in the Dockerfile)
#
# shellcheck disable=SC2068
exec $@
