FROM python:3.6-alpine

RUN apk add --no-cache \
      bash \
      build-base \
      ca-certificates \
      cyrus-sasl-dev \
      graphviz \
      jpeg-dev \
      libffi-dev \
      libxml2-dev \
      libxslt-dev \
      openldap-dev \
      openssl-dev \
      postgresql-dev \
      wget \
  && pip install gunicorn==17.5

WORKDIR /opt

ARG BRANCH=master
ARG URL=https://github.com/digitalocean/netbox/archive/$BRANCH.tar.gz
RUN wget -q -O - "${URL}" | tar xz \
  && mv netbox* netbox

WORKDIR /opt/netbox
RUN pip install -r requirements.txt

RUN ln -s configuration.docker.py netbox/netbox/configuration.py
COPY docker/gunicorn_config.py /opt/netbox/
COPY docker/nginx.conf /etc/netbox-nginx/nginx.conf

COPY docker/docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]

VOLUME ["/etc/netbox-nginx/"]
