#!/bin/bash
set -euo pipefail

# Build NetBox 3.4.1 with Ubuntu 24.04 (Python 3.12)
# Fixes: django.utils.itercompat removed in Django 5.1+
#   - --frozen flag prevents uv from upgrading Django==4.1.4
#   - Post-install sed patch fixes itercompat import as safety net
#   - libjpeg-dev added for image processing support
#   - django-auth-ldap downgraded to 4.8.0 (compatible with Django 4.1)
#   - mkdocs build skipped (not needed in container)
#   - social-auth-core sed pattern fixed to handle existing extras

NETBOX_VERSION="3.4.1"
REGISTRY="registry2-quay-quay-enterprise2.apps.luke.syangsao.net"
IMAGE="${REGISTRY}/openshift/netbox:${NETBOX_VERSION}"

cd ~/netbox-docker

echo "🏗 Building NetBox ${NETBOX_VERSION} with Ubuntu 24.04 base..."
podman build \
  --pull \
  --no-cache \
  --target main \
  -f Dockerfile \
  -t "${IMAGE}" \
  --build-arg "FROM=docker.io/ubuntu:24.04" \
  --build-arg "NETBOX_PATH=.netbox" \
  --label "org.opencontainers.image.version=${NETBOX_VERSION}" \
  .

echo "📤 Pushing to ${REGISTRY}..."
podman push "${IMAGE}"

echo "✅ Done! Image: ${IMAGE}"
