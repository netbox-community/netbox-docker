#!/bin/bash
set -e

# run db migrations (retry on error)
while ! ./manage.py migrate 2>&1; do
    sleep 5
done

# create superuser silently
if [[ -z ${SUPERUSER_NAME} || -z ${SUPERUSER_EMAIL} || -z ${SUPERUSER_PASSWORD} ]]; then
        SUPERUSER_NAME='admin'
        SUPERUSER_EMAIL='admin@example.com'
        SUPERUSER_PASSWORD='admin'
        echo "Using defaults: Username: ${SUPERUSER_NAME}, E-Mail: ${SUPERUSER_EMAIL}, Password: ${SUPERUSER_PASSWORD}"
fi

./manage.py shell --plain << END
from django.contrib.auth.models import User
if not User.objects.filter(username='${SUPERUSER_NAME}'):
    User.objects.create_superuser('${SUPERUSER_NAME}', '${SUPERUSER_EMAIL}', '${SUPERUSER_PASSWORD}')
END

# copy static files
./manage.py collectstatic --no-input

echo "✅ Initialisation is done. Launching CMD:"
echo "exec ${@}"

# launch whatever is passed by docker via RUN
exec ${@}
