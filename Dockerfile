ARG FROM
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
      django_auth_ldap \
# django-storages was introduced in 2.7 and is optional
      django-storages

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
COPY docker/gunicorn_config.py /etc/netbox/
COPY docker/nginx.conf /etc/netbox-nginx/nginx.conf
COPY docker/docker-entrypoint.sh /opt/netbox/docker-entrypoint.sh
COPY startup_scripts/ /opt/netbox/startup_scripts/
COPY initializers/ /opt/netbox/initializers/
COPY configuration/ /etc/netbox/config/

WORKDIR /opt/netbox/netbox

# Must set permissions for '/opt/netbox/netbox/static' directory
# to g+w so that `./manage.py collectstatic` can be executed during
# container startup.
# Must set permissions for '/opt/netbox/netbox/media' directory
# to g+w so that pictures can be uploaded to netbox.
RUN mkdir static && chmod -R g+w static media

ENTRYPOINT [ "/opt/netbox/docker-entrypoint.sh" ]

CMD ["gunicorn", "-c /etc/netbox/gunicorn_config.py", "netbox.wsgi"]

LABEL ORIGINAL_TAG="" \
      NETBOX_GIT_BRANCH="" \
      NETBOX_GIT_REF="" \
      NETBOX_GIT_URL="" \
# See http://label-schema.org/rc1/#build-time-labels
# Also https://microbadger.com/labels
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date="" \
      org.label-schema.name="Netbox Docker" \
      org.label-schema.description="A container based distribution of Netbox, the free and open IPAM and DCIM solution." \
      org.label-schema.vendor="The netbox-docker contributors." \
      org.label-schema.url="https://github.com/netbox-community/netbox-docker" \
      org.label-schema.usage="https://github.com/netbox-community/netbox-docker/wiki" \
      org.label-schema.vcs-url="https://github.com/netbox-community/netbox-docker.git" \
      org.label-schema.vcs-ref="" \
      org.label-schema.version="snapshot" \
# See https://github.com/opencontainers/image-spec/blob/master/annotations.md#pre-defined-annotation-keys
      org.opencontainers.image.created="" \
      org.opencontainers.image.title="Netbox Docker" \
      org.opencontainers.image.description="A container based distribution of Netbox, the free and open IPAM and DCIM solution." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.authors="The netbox-docker contributors." \
      org.opencontainers.image.vendor="The netbox-docker contributors." \
      org.opencontainers.image.url="https://github.com/netbox-community/netbox-docker" \
      org.opencontainers.image.documentation="https://github.com/netbox-community/netbox-docker/wiki" \
      org.opencontainers.image.source="https://github.com/netbox-community/netbox-docker.git" \
      org.opencontainers.image.revision="" \
      org.opencontainers.image.version="snapshot"

#####
## LDAP specific configuration
#####

FROM main as ldap

RUN apk add --no-cache \
      libsasl \
      libldap \
      util-linux

COPY docker/ldap_config.docker.py /opt/netbox/netbox/netbox/ldap_config.py
