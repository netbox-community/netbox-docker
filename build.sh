#!/bin/bash

set -e

if [ "${1}x" == "x" ] || [ "${1}" == "--help" ] || [ "${1}" == "-h" ]; then
  echo "Usage: ${0} <branch> [--push]"
  echo "  branch  The branch or tag to build. Required."
  echo "  --push  Pushes built Docker image to docker hub."
  echo ""
  echo "You can use the following ENV variables to customize the build:"
  echo "  BRANCH   The branch to build."
  echo "           Also used for tagging the image."
  echo "  DOCKER_REPO The Docker registry (i.e. hub.docker.com/r/DOCKER_REPO/netbox) "
  echo "           Also used for tagging the image."
  echo "           Default: ninech"
  echo "  SRC_REPO Which fork of netbox to use (i.e. github.com/<SRC_REPO>/netbox)."
  echo "           Default: digitalocean"
  echo "  URL      Where to fetch the package from."
  echo "           Must be a tar.gz file of the source code."
  echo "           Default: https://github.com/\${SRC_REPO}/netbox/archive/\$BRANCH.tar.gz"

  if [ "${1}x" == "x" ]; then
    exit 1
  else
    exit 0
  fi
fi

SRC_REPO="${SRC_REPO-digitalocean}"
DOCKER_REPO="${DOCKER_REPO-ninech}"
BRANCH="${1}"
URL="${URL-https://github.com/${SRC_REPO}/netbox/archive/$BRANCH.tar.gz}"

if [ "${BRANCH}" == "master" ]; then
  TAG="${TAG-latest}"
  CACHE="--no-cache"
elif [ "${BRANCH}" == "develop" ]; then
  TAG="${TAG-snapshot}"
  CACHE="--no-cache"
else
  TAG="${TAG-$BRANCH}"
  CACHE=""
fi

echo "🐳 Building the Docker image '${DOCKER_REPO}/netbox:${TAG}' from the branch '${BRANCH}'."
docker build -t "${DOCKER_REPO}/netbox:${TAG}" --build-arg "BRANCH=${BRANCH}" --build-arg "URL=${URL}" --pull ${CACHE} .
echo "✅ Finished building the Docker images '${DOCKER_REPO}/netbox:${TAG}'"

if [ "${2}" == "--push" ] ; then
  echo "⏫ Pushing '${DOCKER_REPO}/netbox:${BRANCH}"
  docker push "${DOCKER_REPO}/netbox:${TAG}"
  echo "✅ Finished pushing the Docker image '${DOCKER_REPO}/netbox:${TAG}'."
fi
