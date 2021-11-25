ARG FROM
FROM ${FROM} as builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
  && apt-get install \
      --yes -qq --no-install-recommends \
      build-essential \
      ca-certificates \
      graphviz \
      libevent-dev \
      libffi-dev \
      libjpeg-dev \
      libldap-dev \
      libsasl2-dev \
      libxslt1-dev \
      libxml2-dev \
      postgresql-13 \
      python3-dev \
      python3-pip \
      python3-venv \
  && python3 -m venv /opt/netbox/venv \
  && /opt/netbox/venv/bin/python3 -m pip install --upgrade \
      pip \
      setuptools \
      wheel

WORKDIR /opt/netbox/

ARG NETBOX_PATH
COPY ${NETBOX_PATH}/requirements.txt requirements-container.txt /
RUN /opt/netbox/venv/bin/pip install \
      -r /requirements.txt \
      -r /requirements-container.txt

###
# Main stage
###

ARG FROM
FROM ${FROM} as main

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8
RUN . /etc/os-release \
  && apt-get update -qq \
  && apt-get upgrade \
      --yes -qq --no-install-recommends \
  && apt-get install \
      --yes -qq --no-install-recommends \
      ca-certificates \
      curl \
      openssl \
      postgresql-client \
      python3 \
      python3-distutils \
  && curl -sL https://nginx.org/keys/nginx_signing.key | \
    tee /etc/apt/trusted.gpg.d/nginx.asc \
  && echo "deb https://packages.nginx.org/unit/debian/ ${VERSION_CODENAME} unit" | \
    tee /etc/apt/sources.list.d/unit.list \
  && apt-get update -qq \
  && apt-get install \
      --yes -qq --no-install-recommends \
      unit=1.26.0-1~bullseye \
      unit-python3.9=1.26.0-1~bullseye \
      tini \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

COPY --from=builder /opt/netbox/venv /opt/netbox/venv

ARG NETBOX_PATH
COPY ${NETBOX_PATH} /opt/netbox

COPY docker/configuration.docker.py /opt/netbox/netbox/netbox/configuration.py
COPY docker/ldap_config.docker.py /opt/netbox/netbox/netbox/ldap_config.py
COPY docker/docker-entrypoint.sh /opt/netbox/docker-entrypoint.sh
COPY docker/housekeeping.sh /opt/netbox/housekeeping.sh
COPY docker/launch-netbox.sh /opt/netbox/launch-netbox.sh
COPY startup_scripts/ /opt/netbox/startup_scripts/
COPY initializers/ /opt/netbox/initializers/
COPY configuration/ /etc/netbox/config/
COPY docker/nginx-unit.json /etc/unit/

WORKDIR /opt/netbox

# Must set permissions for '/opt/netbox/netbox/media' directory
# to g+w so that pictures can be uploaded to netbox.
RUN mkdir -p static /opt/unit/state/ /opt/unit/tmp/ \
      && chown -R unit:root /opt/netbox/netbox/media /opt/unit/ \
      && chmod -R g+w /opt/netbox/netbox/media /opt/unit/ \
      && /opt/netbox/venv/bin/python -m mkdocs build \
          --config-file /opt/netbox/mkdocs.yml --site-dir /opt/netbox/netbox/project-static/docs/ \
      && SECRET_KEY="dummy" /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py collectstatic --no-input

WORKDIR /opt/netbox/netbox
ENTRYPOINT [ "/usr/bin/tini", "--" ]

CMD [ "/opt/netbox/docker-entrypoint.sh", "/opt/netbox/launch-netbox.sh" ]

LABEL ORIGINAL_TAG="" \
      NETBOX_GIT_BRANCH="" \
      NETBOX_GIT_REF="" \
      NETBOX_GIT_URL="" \
# See https://github.com/opencontainers/image-spec/blob/master/annotations.md#pre-defined-annotation-keys
      org.opencontainers.image.created="" \
      org.opencontainers.image.title="NetBox Docker" \
      org.opencontainers.image.description="A container based distribution of NetBox, the free and open IPAM and DCIM solution." \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.authors="The netbox-docker contributors." \
      org.opencontainers.image.vendor="The netbox-docker contributors." \
      org.opencontainers.image.url="https://github.com/netbox-community/netbox-docker" \
      org.opencontainers.image.documentation="https://github.com/netbox-community/netbox-docker/wiki" \
      org.opencontainers.image.source="https://github.com/netbox-community/netbox-docker.git" \
      org.opencontainers.image.revision="" \
      org.opencontainers.image.version="snapshot"
