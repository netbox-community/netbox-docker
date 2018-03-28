FROM python:3.6-alpine

RUN apk add --no-cache \
      bash \
      build-base \
      ca-certificates \
      cyrus-sasl-dev \
      graphviz \
      ttf-ubuntu-font-family \
      jpeg-dev \
      libffi-dev \
      libxml2-dev \
      libxslt-dev \
      openldap-dev \
      openssl-dev \
      postgresql-dev \
      wget

RUN pip install \
# gunicorn is used for launching netbox
      gunicorn \
# napalm is used for gathering information from network devices
      napalm \
# ruamel is used in startup_scripts
      ruamel.yaml

WORKDIR /opt

ARG RELEASE=v2.3.2
ARG URL=https://github.com/digitalocean/netbox/archive/$RELEASE.tar.gz
RUN wget -q -O - "${URL}" | tar xz \
  && mv netbox* netbox

WORKDIR /opt/netbox
RUN pip install -r requirements.txt

COPY docker/configuration.docker.py /opt/netbox/netbox/netbox/configuration.py
COPY configuration/gunicorn_config.py /etc/netbox/
COPY docker/nginx.conf /etc/netbox-nginx/nginx.conf
COPY docker/docker-entrypoint.sh docker-entrypoint.sh
COPY startup_scripts/ /opt/netbox/startup_scripts/
COPY initializers/ /opt/netbox/initializers/
COPY configuration/configuration.py /etc/netbox/configuration.py

WORKDIR /opt/netbox/netbox

ENTRYPOINT [ "/opt/netbox/docker-entrypoint.sh" ]

VOLUME ["/etc/netbox-nginx/"]

CMD ["gunicorn", "-c /etc/netbox/gunicorn_config.py", "netbox.wsgi"]

LABEL SRC_URL="$URL"
