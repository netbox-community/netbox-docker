#!/bin/bash
set -e

# run db migrations (retry on error)
while ! /opt/netbox/netbox/manage.py migrate 2>&1; do
    sleep 5
done

# create superuser silently
if [[ -z ${SUPERUSER_NAME} || -z ${SUPERUSER_EMAIL} || -z ${SUPERUSER_PASSWORD} ]]; then
        SUPERUSER_NAME='admin'
        SUPERUSER_EMAIL='admin@example.com'
        SUPERUSER_PASSWORD='admin'
        echo "Using defaults: Username: ${SUPERUSER_NAME}, E-Mail: ${SUPERUSER_EMAIL}, Password: ${SUPERUSER_PASSWORD}"
fi

python netbox/manage.py shell --plain << END
from django.contrib.auth.models import User
if not User.objects.filter(username='${SUPERUSER_NAME}'):
    User.objects.create_superuser('${SUPERUSER_NAME}', '${SUPERUSER_EMAIL}', '${SUPERUSER_PASSWORD}')
END

# copy static files
/opt/netbox/netbox/manage.py collectstatic --no-input

# start unicorn
gunicorn --log-level debug --debug --error-logfile /dev/stderr --log-file /dev/stdout -c /opt/netbox/gunicorn_config.py netbox.wsgi
