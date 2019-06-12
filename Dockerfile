FROM python:3.6-alpine3.9

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
      postgresql-dev \
      ttf-ubuntu-font-family \
      wget

RUN pip install \
# gunicorn is used for launching netbox
      gunicorn \
# napalm is used for gathering information from network devices
      napalm \
# ruamel is used in startup_scripts
      ruamel.yaml \
# pinning django to the version required by netbox
# adding it here, to install the correct version of
# django-rq
      'Django>=2.2,<2.3' \
# django-rq is used for webhooks
      django-rq

ARG BRANCH=master

WORKDIR /tmp

# As the requirements don't change very often,
# and as they take some time to compile,
# we try to cache them very agressively.
ARG REQUIREMENTS_URL=https://raw.githubusercontent.com/digitalocean/netbox/$BRANCH/requirements.txt
ADD ${REQUIREMENTS_URL} requirements.txt
RUN pip install -r requirements.txt

# Cache bust when the upstream branch changes:
# ADD will fetch the file and check if it has changed
# If not, Docker will use the existing build cache.
# If yes, Docker will bust the cache and run every build step from here on.
ARG REF_URL=https://api.github.com/repos/digitalocean/netbox/contents?ref=$BRANCH
ADD ${REF_URL} version.json

WORKDIR /opt

ARG URL=https://github.com/digitalocean/netbox/archive/$BRANCH.tar.gz
RUN wget -q -O - "${URL}" | tar xz \
  && mv netbox* netbox

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

LABEL SRC_URL="$URL"

ARG NETBOX_DOCKER_PROJECT_VERSION=snapshot
LABEL NETBOX_DOCKER_PROJECT_VERSION="$NETBOX_DOCKER_PROJECT_VERSION"
