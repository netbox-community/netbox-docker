ARG DOCKER_ORG=netboxcommunity
ARG DOCKER_REPO=netbox
ARG FROM_TAG=latest
FROM $DOCKER_ORG/$DOCKER_REPO:$FROM_TAG

RUN pip install django_auth_ldap

COPY docker/ldap_config.docker.py /opt/netbox/netbox/netbox/ldap_config.py
COPY configuration/ldap_config.py /etc/netbox/config/ldap_config.py
