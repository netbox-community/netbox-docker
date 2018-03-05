#!/bin/bash
# Builds the Dockerfile[.variant] and injects tgz'ed Netbox code from Github

set -e

if [ "${1}x" == "x" ] || [ "${1}" == "--help" ] || [ "${1}" == "-h" ]; then
  echo "Usage: ${0} <branch> [--push]"
  echo "  branch  The branch or tag to build. Required."
  echo "  --push  Pushes built Docker image to docker hub."
  echo ""
  echo "You can use the following ENV variables to customize the build:"
  echo "  DEBUG    If defined, the script does not stop when certain checks are unsatisfied."
  echo "  DRY_RUN  Prints all build statements instead of running them."
  echo "  DOCKER_OPTS Add parameters to Docker."
  echo "           Default:"
  echo "             When <TAG> starts with 'v':  \"\""
  echo "             Else:                        \"--no-cache\""
  echo "  BRANCH   The branch to build."
  echo "           Also used for tagging the image."
  echo "  TAG      The version part of the docker tag."
  echo "           Default:"
  echo "             When <BRANCH>=master:  latest"
  echo "             When <BRANCH>=develop: snapshot"
  echo "             Else:          same as <BRANCH>"
  echo "  DOCKER_ORG The Docker registry (i.e. hub.docker.com/r/<DOCKER_ORG>/<DOCKER_REPO>) "
  echo "           Also used for tagging the image."
  echo "           Default: ninech"
  echo "  DOCKER_REPO The Docker registry (i.e. hub.docker.com/r/<DOCKER_ORG>/<DOCKER_REPO>) "
  echo "           Also used for tagging the image."
  echo "           Default: netbox"
  echo "  DOCKER_TAG The name of the tag which is applied to the image."
  echo "           Useful for pushing into another registry than hub.docker.com."
  echo "           Default: <DOCKER_ORG>/<DOCKER_REPO>:<BRANCH>"
  echo "  SRC_ORG  Which fork of netbox to use (i.e. github.com/<SRC_ORG>/<SRC_REPO>)."
  echo "           Default: digitalocean"
  echo "  SRC_REPO The name of the netbox for to use (i.e. github.com/<SRC_ORG>/<SRC_REPO>)."
  echo "           Default: netbox"
  echo "  URL      Where to fetch the package from."
  echo "           Must be a tar.gz file of the source code."
  echo "           Default: https://github.com/<SRC_ORG>/<SRC_REPO>/archive/\$BRANCH.tar.gz"
  echo "  VARIANT  The variant to build."
  echo "           The value will be used as a suffix to the \$TAG and for the Dockerfile"
  echo "           selection. The TAG being build must exist for the base variant and"
  echo "           corresponding Dockerfile must start with the following lines:"
  echo "             ARG DOCKER_ORG=ninech"
  echo "             ARG DOCKER_REPOT=netbox"
  echo "             ARG FROM_TAG=latest"
  echo "             FROM \$DOCKER_ORG/\$DOCKER_REPO:\$FROM_TAG"
  echo "           Example: VARIANT=ldap will result in the tag 'latest-ldap' and the"
  echo "            Dockerfile 'Dockerfile.ldap' being used."
  echo "           Default: empty"

  if [ "${1}x" == "x" ]; then
    exit 1
  else
    exit 0
  fi
fi

# variables for fetching the source
SRC_ORG="${SRC_ORG-digitalocean}"
SRC_REPO="${SRC_REPO-netbox}"
BRANCH="${1}"
URL="${URL-https://github.com/${SRC_ORG}/${SRC_REPO}/archive/$BRANCH.tar.gz}"

# variables for tagging the docker image
DOCKER_ORG="${DOCKER_ORG-ninech}"
DOCKER_REPO="${DOCKER_REPO-netbox}"
case "${BRANCH}" in
  master)
    TAG="${TAG-latest}";;
  develop)
    TAG="${TAG-snapshot}";;
  *)
    TAG="${TAG-$BRANCH}";;
esac
DOCKER_TAG="${DOCKER_TAG-${DOCKER_ORG}/${DOCKER_REPO}:${TAG}}"

# caching is only ok for version tags
case "${TAG}" in
  v*)
    CACHE="${CACHE-}";;
  *)
    CACHE="${CACHE---no-cache}";;
esac

# Checking which VARIANT to build
if [ -z "$VARIANT" ]; then
  DOCKERFILE="Dockerfile"
else
  DOCKERFILE="Dockerfile.${VARIANT}"
  DOCKER_TAG="${DOCKER_TAG}-${VARIANT}"

  # Fail fast
  if [ ! -f "${DOCKERFILE}" ]; then
    echo "🚨 The Dockerfile ${DOCKERFILE} for variant '${VARIANT}' doesn't exist."

    if [ -z "$DEBUG" ]; then
      exit 1
    else
      echo "⚠️ Would exit here with code '1', but DEBUG is enabled."
    fi
  fi
fi

# Docker options
DOCKER_OPTS=(
  "$CACHE"
  --pull
)

# Build args
DOCKER_BUILD_ARGS=(
  --build-arg "FROM_TAG=${TAG}"
  --build-arg "BRANCH=${BRANCH}"
  --build-arg "URL=${URL}"
  --build-arg "DOCKER_ORG=${DOCKER_ORG}"
  --build-arg "DOCKER_REPO=${DOCKER_REPO}"
)

if [ -z "$DRY_RUN" ]; then
  DOCKER_CMD="docker"
else
  echo "⚠️ DRY_RUN MODE ON ⚠️"
  DOCKER_CMD="echo docker"
fi

echo "🐳 Building the Docker image '${DOCKER_TAG}' from the url '${URL}'."
$DOCKER_CMD build -t "${DOCKER_TAG}" "${DOCKER_BUILD_ARGS[@]}" "${DOCKER_OPTS[@]}" -f "${DOCKERFILE}" .
echo "✅ Finished building the Docker images '${DOCKER_TAG}'"

if [ "${2}" == "--push" ] ; then
  echo "⏫ Pushing '${DOCKER_TAG}"
  $DOCKER_CMD push "${DOCKER_TAG}"
  echo "✅ Finished pushing the Docker image '${DOCKER_TAG}'."
fi
