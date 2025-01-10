ARG FROM
FROM ${FROM} AS builder

RUN \
    zypper -n in \
      gcc \
      openldap2-devel \
      postgresql-devel \
      postgresql-server-devel \
      cyrus-sasl-devel \
      libopenssl-devel \
      libxml2-devel \
      libxml-security-c-devel \
      libxslt-devel \
    && python3 -m venv /opt/netbox/venv \
    && /opt/netbox/venv/bin/python3 -m pip install --upgrade \
      pip \
      setuptools \
      wheel \
    && zypper -n cc -a && rm -r /var/{cache,log}/*

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

RUN \
    zypper -n in \
      bzip2 \
      libpq5 \
      libxmlsec1-openssl1 \
      openssh-clients \
      catatonit \
    && zypper -n ar -G -f -p 100 https://packages.nginx.org/unit/fedora/38/x86_64/ nginx-unit \
    && zypper -n in \
      unit-python311 \
    && zypper -n cc -a && rm -r /var/{cache,log}/*

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

# Plugins and plugin configuration
COPY ./plugin_requirements.txt /opt/netbox/
COPY configuration/configuration.py /etc/netbox/config/configuration.py
COPY configuration/plugins.py /etc/netbox/config/plugins.py

# Plugin configuration only possible via settings.py
COPY ./local_settings.py /opt/netbox/netbox/netbox/

# Install plugins
RUN /opt/netbox/venv/bin/pip install  --no-warn-script-location -r /opt/netbox/plugin_requirements.txt
RUN SECRET_KEY="dummydummydummydummydummydummydummydummydummydummy" /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py collectstatic --no-input

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
ENTRYPOINT [ "catatonit", "--" ]

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
