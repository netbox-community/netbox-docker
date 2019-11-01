ARG FROM=python:3.7-alpine
FROM ${FROM} as builder

RUN apk add --no-cache \
      bash \
      build-base \
      ca-certificates \
      cyrus-sasl-dev \
      graphviz \
      jpeg-dev \
      libevent-dev \
      libffi-dev \
      libxslt-dev \
      openldap-dev \
      postgresql-dev

WORKDIR /install

RUN pip install --prefix="/install" --no-warn-script-location \
# gunicorn is used for launching netbox
      gunicorn \
      greenlet \
      eventlet \
# napalm is used for gathering information from network devices
      napalm \
# ruamel is used in startup_scripts
      'ruamel.yaml>=0.15,<0.16' \
# django_auth_ldap is required for ldap
      django_auth_ldap

ARG NETBOX_PATH
COPY ${NETBOX_PATH}/requirements.txt /
RUN pip install --prefix="/install" --no-warn-script-location -r /requirements.txt

###
# Main stage
###

ARG FROM
FROM ${FROM} as main

RUN apk add --no-cache \
      bash \
      ca-certificates \
      graphviz \
      libevent \
      libffi \
      libjpeg-turbo \
      libressl \
      libxslt \
      postgresql-libs \
      ttf-ubuntu-font-family

WORKDIR /opt

COPY --from=builder /install /usr/local

ARG NETBOX_PATH
COPY ${NETBOX_PATH} /opt/netbox

COPY docker/configuration.docker.py /opt/netbox/netbox/netbox/configuration.py
COPY configuration/gunicorn_config.py /etc/netbox/config/
COPY docker/nginx.conf /etc/netbox-nginx/nginx.conf
COPY docker/docker-entrypoint.sh /opt/netbox/docker-entrypoint.sh
COPY startup_scripts/ /opt/netbox/startup_scripts/
COPY initializers/ /opt/netbox/initializers/
COPY configuration/configuration.py /etc/netbox/config/configuration.py

WORKDIR /opt/netbox/netbox

ENTRYPOINT [ "/opt/netbox/docker-entrypoint.sh" ]

CMD ["gunicorn", "-c /etc/netbox/config/gunicorn_config.py", "netbox.wsgi"]

LABEL NETBOX_DOCKER_PROJECT_VERSION="custom build" \
      NETBOX_BRANCH="custom build" \
      ORIGINAL_DOCKER_TAG="custom build" \
      NETBOX_GIT_COMMIT="not built from git" \
      NETBOX_GIT_URL="not built from git"

#####
## LDAP specific configuration
#####

FROM main as ldap

RUN apk add --no-cache \
      libsasl \
      libldap \
      util-linux

COPY docker/ldap_config.docker.py /opt/netbox/netbox/netbox/ldap_config.py
COPY configuration/ldap_config.py /etc/netbox/config/ldap_config.py
