ARG FROM
FROM ${FROM} AS builder

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -qq \
    && apt-get upgrade \
      --yes -qq --no-install-recommends \
    && apt-get install \
      --yes -qq --no-install-recommends \
      build-essential \
      ca-certificates \
      libldap-dev \
      libpq-dev \
      libsasl2-dev \
      libssl-dev \
      libxml2-dev \
      libxmlsec1 \
      libxmlsec1-dev \
      libxmlsec1-openssl \
      libxslt-dev \
      pkg-config \
      python3-dev \
      python3-pip \
      python3-venv \
    && python3 -m venv /opt/netbox/venv \
    && /opt/netbox/venv/bin/python3 -m pip install --upgrade \
      pip \
      setuptools \
      wheel

ARG NETBOX_PATH
COPY ${NETBOX_PATH}/requirements.txt requirements-container.txt /
RUN \
    # Gunicorn is not needed because we use Nginx Unit
    sed -i -e '/gunicorn/d' /requirements.txt && \
    # We need 'social-auth-core[all]' in the Docker image. But if we put it in our own requirements-container.txt
    # we have potential version conflicts and the build will fail.
    # That's why we just replace it in the original requirements.txt.
    sed -i -e 's/social-auth-core/social-auth-core\[all\]/g' /requirements.txt && \
    /opt/netbox/venv/bin/pip install \
      -r /requirements.txt \
      -r /requirements-container.txt

###
# Main stage
###

ARG FROM
FROM ${FROM} AS main

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -qq \
    && apt-get upgrade \
      --yes -qq --no-install-recommends \
    && apt-get install \
      --yes -qq --no-install-recommends \
      bzip2 \
      ca-certificates \
      curl \
      libldap-common \
      libpq5 \
      libxmlsec1-openssl \
      openssh-client \
      openssl \
      python3 \
      tini \
    && curl --silent --output /usr/share/keyrings/nginx-keyring.gpg \
      https://unit.nginx.org/keys/nginx-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-keyring.gpg] https://packages.nginx.org/unit/ubuntu/ noble unit" \
      > /etc/apt/sources.list.d/unit.list \
    && apt-get update -qq \
    && apt-get install \
      --yes -qq --no-install-recommends \
      unit=1.33.0-1~noble \
      unit-python3.12=1.33.0-1~noble \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/netbox/venv /opt/netbox/venv

ARG NETBOX_PATH
COPY ${NETBOX_PATH} /opt/netbox
# Copy the modified 'requirements*.txt' files, to have the files actually used during installation
COPY --from=builder /requirements.txt /requirements-container.txt /opt/netbox/

COPY docker/configuration.docker.py /opt/netbox/netbox/netbox/configuration.py
COPY docker/ldap_config.docker.py /opt/netbox/netbox/netbox/ldap_config.py
COPY docker/docker-entrypoint.sh /opt/netbox/docker-entrypoint.sh
COPY docker/housekeeping.sh /opt/netbox/housekeeping.sh
COPY docker/launch-netbox.sh /opt/netbox/launch-netbox.sh
COPY configuration/ /etc/netbox/config/
COPY docker/nginx-unit.json /etc/unit/

WORKDIR /opt/netbox/netbox

# Must set permissions for '/opt/netbox/netbox/media' directory
# to g+w so that pictures can be uploaded to netbox.
RUN mkdir -p static /opt/unit/state/ /opt/unit/tmp/ \
      && chown -R unit:root /opt/unit/ media reports scripts \
      && chmod -R g+w /opt/unit/ media reports scripts \
      && cd /opt/netbox/ && SECRET_KEY="dummyKeyWithMinimumLength-------------------------" /opt/netbox/venv/bin/python -m mkdocs build \
          --config-file /opt/netbox/mkdocs.yml --site-dir /opt/netbox/netbox/project-static/docs/ \
      && SECRET_KEY="dummyKeyWithMinimumLength-------------------------" /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py collectstatic --no-input

ENV LANG=C.utf8 PATH=/opt/netbox/venv/bin:$PATH
ENTRYPOINT [ "/usr/bin/tini", "--" ]

CMD [ "/opt/netbox/docker-entrypoint.sh", "/opt/netbox/launch-netbox.sh" ]

LABEL netbox.original-tag="" \
      netbox.git-branch="" \
      netbox.git-ref="" \
      netbox.git-url="" \
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
      org.opencontainers.image.version=""
