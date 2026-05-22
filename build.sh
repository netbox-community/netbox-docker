#!/bin/bash
set -euo pipefail
cd /opt/data/netbox-docker
docker build \
  --pull \
  --no-cache \
  --target main \
  -f Dockerfile \
  -t "registry2-quay-quay-enterprise2.apps.luke.syangsao.net/openshift/netbox:3.4.1" \
  --build-arg "FROM=docker.io/ubuntu:24.04" \
  --build-arg "NETBOX_PATH=.netbox" \
  --label "org.opencontainers.image.version=3.4.1" \
  .
