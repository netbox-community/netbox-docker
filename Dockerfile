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
# ruamel is used in startup_scripts
      ruamel.yaml

WORKDIR /opt

ARG BRANCH=master
ARG URL=https://github.com/digitalocean/netbox/archive/$BRANCH.tar.gz
RUN wget -q -O - "${URL}" | tar xz \
  && mv netbox* netbox

WORKDIR /opt/netbox
RUN pip install -r requirements.txt
RUN pip install django_auth_ldap

COPY docker/configuration.docker.py /opt/netbox/netbox/netbox/configuration.py
COPY docker/ldap_config.docker.py /opt/netbox/netbox/netbox/ldap_config.py
COPY docker/gunicorn_config.py /opt/netbox/
COPY docker/nginx.conf /etc/netbox-nginx/nginx.conf
COPY docker/docker-entrypoint.sh docker-entrypoint.sh
COPY startup_scripts/ /opt/netbox/startup_scripts/
COPY initializers/ /opt/netbox/initializers/

WORKDIR /opt/netbox/netbox

ENTRYPOINT [ "/opt/netbox/docker-entrypoint.sh" ]

VOLUME ["/etc/netbox-nginx/"]

CMD ["gunicorn", "--log-level debug", "-c /opt/netbox/gunicorn_config.py", "netbox.wsgi"]

LABEL SRC_URL="$URL"
