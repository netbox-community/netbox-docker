ARG FROM
FROM ${FROM} as builder

RUN apk add --no-cache \
      bash \
      build-base \
      cargo \
      ca-certificates \
      cmake \
      cyrus-sasl-dev \
      git \
      graphviz \
      jpeg-dev \
      libevent-dev \
      libffi-dev \
      libxslt-dev \
      make \
      musl-dev \
      openldap-dev \
      postgresql-dev \
      py3-pip \
      python3-dev \
  && python3 -m venv /opt/netbox/venv \
  && /opt/netbox/venv/bin/python3 -m pip install --upgrade \
      pip \
      setuptools \
      wheel

# Build libcrc32c for google-crc32c python module
RUN git clone https://github.com/google/crc32c \
    && cd crc32c \
    && git submodule update --init --recursive \
    && mkdir build \
    && cd build \
    && cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DCRC32C_BUILD_TESTS=no \
        -DCRC32C_BUILD_BENCHMARKS=no \
        -DBUILD_SHARED_LIBS=yes \
        .. \
    && make all install

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

RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      graphviz \
      libevent \
      libffi \
      libjpeg-turbo \
      libxslt \
      openssl \
      postgresql-client \
      postgresql-libs \
      py3-pip \
      python3 \
      tini \
      unit \
      unit-python3

WORKDIR /opt

COPY --from=builder /usr/local/lib/libcrc32c.* /usr/local/lib/
COPY --from=builder /usr/local/include/crc32c /usr/local/include
COPY --from=builder /usr/local/lib/cmake/Crc32c /usr/local/lib/cmake/
COPY --from=builder /opt/netbox/venv /opt/netbox/venv

ARG NETBOX_PATH
COPY ${NETBOX_PATH} /opt/netbox

COPY docker/configuration.docker.py /opt/netbox/netbox/netbox/configuration.py
COPY docker/docker-entrypoint.sh /opt/netbox/docker-entrypoint.sh
COPY docker/housekeeping.sh /opt/netbox/housekeeping.sh
COPY docker/launch-netbox.sh /opt/netbox/launch-netbox.sh
COPY startup_scripts/ /opt/netbox/startup_scripts/
COPY initializers/ /opt/netbox/initializers/
COPY configuration/ /etc/netbox/config/
COPY docker/nginx-unit.json /etc/unit/

WORKDIR /opt/netbox/netbox

# Must set permissions for '/opt/netbox/netbox/media' directory
# to g+w so that pictures can be uploaded to netbox.
RUN mkdir -p static /opt/unit/state/ /opt/unit/tmp/ \
      && chown -R unit:root media /opt/unit/ \
      && chmod -R g+w media /opt/unit/ \
      && cd /opt/netbox/ && SECRET_KEY="dummy" /opt/netbox/venv/bin/python -m mkdocs build \
          --config-file /opt/netbox/mkdocs.yml --site-dir /opt/netbox/netbox/project-static/docs/ \
      && SECRET_KEY="dummy" /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py collectstatic --no-input

ENTRYPOINT [ "/sbin/tini", "--" ]

CMD [ "/opt/netbox/docker-entrypoint.sh", "/opt/netbox/launch-netbox.sh" ]

LABEL ORIGINAL_TAG="" \
      NETBOX_GIT_BRANCH="" \
      NETBOX_GIT_REF="" \
      NETBOX_GIT_URL="" \
# See http://label-schema.org/rc1/#build-time-labels
# Also https://microbadger.com/labels
      org.label-schema.schema-version="1.0" \
      org.label-schema.build-date="" \
      org.label-schema.name="NetBox Docker" \
      org.label-schema.description="A container based distribution of NetBox, the free and open IPAM and DCIM solution." \
      org.label-schema.vendor="The netbox-docker contributors." \
      org.label-schema.url="https://github.com/netbox-community/netbox-docker" \
      org.label-schema.usage="https://github.com/netbox-community/netbox-docker/wiki" \
      org.label-schema.vcs-url="https://github.com/netbox-community/netbox-docker.git" \
      org.label-schema.vcs-ref="" \
      org.label-schema.version="snapshot" \
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

#####
## LDAP specific configuration
#####

FROM main as ldap

RUN apk add --no-cache \
      libsasl \
      libldap \
      util-linux

COPY docker/ldap_config.docker.py /opt/netbox/netbox/netbox/ldap_config.py
