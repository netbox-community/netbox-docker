#!/bin/bash
# Builds the Dockerfile and injects tgz'ed Netbox code from Github

echo "▶️ $0 $*"

set -e

if [ "${1}x" == "x" ] || [ "${1}" == "--help" ] || [ "${1}" == "-h" ]; then
  echo "Usage: ${0} <branch> [--push|--push-only]"
  echo "  branch       The branch or tag to build. Required."
  echo "  --push       Pushes built the Docker image to the registry."
  echo "  --push-only  Does not build. Only pushes the Docker image to the registry."
  echo ""
  echo "You can use the following ENV variables to customize the build:"
  echo "  BRANCH   The branch to build."
  echo "           Also used for tagging the image."
  echo "  TAG      The version part of the docker tag."
  echo "           Default:"
  echo "             When <BRANCH>=master:  latest"
  echo "             When <BRANCH>=develop: snapshot"
  echo "             Else:          same as <BRANCH>"
  echo "  DOCKER_OPTS Add parameters to Docker."
  echo "           Default:"
  echo "             When <TAG> starts with 'v':  \"\""
  echo "             Else:                        \"--no-cache\""
  echo "  DOCKER_ORG The Docker registry (i.e. hub.docker.com/r/<DOCKER_ORG>/<DOCKER_REPO>)"
  echo "           Also used for tagging the image."
  echo "           Default: netboxcommunity"
  echo "  DOCKER_REPO The Docker registry (i.e. hub.docker.com/r/<DOCKER_ORG>/<DOCKER_REPO>)"
  echo "           Also used for tagging the image."
  echo "           Default: netbox"
  echo "  DOCKER_FROM The base image to use."
  echo "           Default: Whatever is defined as default in the Dockerfile."
  echo "  DOCKER_TAG The name of the tag which is applied to the image."
  echo "           Useful for pushing into another registry than hub.docker.com."
  echo "           Default: <DOCKER_ORG>/<DOCKER_REPO>:<BRANCH>"
  echo "  DOCKER_SHORT_TAG The name of the short tag which is applied to the"
  echo "           image. This is used to tag all patch releases to their"
  echo "           containing version e.g. v2.5.1 -> v2.5"
  echo "           Default: <DOCKER_ORG>/<DOCKER_REPO>:\$MAJOR.\$MINOR"
  echo "  DOCKERFILE The name of Dockerfile to use."
  echo "           Default: Dockerfile"
  echo "  DOCKER_TARGET A specific target to build."
  echo "           It's currently not possible to pass multiple targets."
  echo "           Default: main ldap"
  echo "  SRC_ORG  Which fork of netbox to use (i.e. github.com/<SRC_ORG>/<SRC_REPO>)."
  echo "           Default: netbox-community"
  echo "  SRC_REPO The name of the netbox for to use (i.e. github.com/<SRC_ORG>/<SRC_REPO>)."
  echo "           Default: netbox"
  echo "  URL      Where to fetch the package from."
  echo "           Must be a tar.gz file of the source code."
  echo "           Default: https://github.com/<SRC_ORG>/<SRC_REPO>/archive/\$BRANCH.tar.gz"
  echo "  HTTP_PROXY The proxy to use for http requests."
  echo "           Example: http://proxy.domain.tld:3128"
  echo "           Default: empty"
  echo "  HTTPS_PROXY The proxy to use for https requests."
  echo "           Example: http://proxy.domain.tld:3128"
  echo "           Default: empty"
  echo "  FTP_PROXY The proxy to use for ftp requests."
  echo "           Example: http://proxy.domain.tld:3128"
  echo "           Default: empty"
  echo "  NO_PROXY Comma-separated list of domain extensions proxy should not be used for."
  echo "           Example: .domain1.tld,.domain2.tld"
  echo "           Default: empty"
  echo "  DEBUG    If defined, the script does not stop when certain checks are unsatisfied."
  echo "  DRY_RUN  Prints all build statements instead of running them."

  if [ "${1}x" == "x" ]; then
    exit 1
  else
    exit 0
  fi
fi

###
# read the project version from the `VERSION` file and trim it
# see https://stackoverflow.com/a/3232433/172132
###
NETBOX_DOCKER_PROJECT_VERSION="${NETBOX_DOCKER_PROJECT_VERSION-$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' VERSION)}"

###
# variables for fetching the source
###
SRC_ORG="${SRC_ORG-netbox-community}"
SRC_REPO="${SRC_REPO-netbox}"
BRANCH="${1}"
URL="${URL-https://github.com/${SRC_ORG}/${SRC_REPO}/archive/$BRANCH.tar.gz}"

###
# Determining the value for DOCKERFILE
# and checking whether it exists
###
DOCKERFILE="${DOCKERFILE-Dockerfile}"
if [ ! -f "${DOCKERFILE}" ]; then
  echo "🚨 The Dockerfile ${DOCKERFILE} doesn't exist."

  if [ -z "$DEBUG" ]; then
    exit 1
  else
    echo "⚠️ Would exit here with code '1', but DEBUG is enabled."
  fi
fi

###
# variables for tagging the docker image
###
DOCKER_ORG="${DOCKER_ORG-netboxcommunity}"
DOCKER_REPO="${DOCKER_REPO-netbox}"
case "${BRANCH}" in
  master)
    TAG="${TAG-latest}";;
  develop)
    TAG="${TAG-snapshot}";;
  *)
    TAG="${TAG-$BRANCH}";;
esac

###
# Determine targets to build
###
DEFAULT_DOCKER_TARGETS=("main" "ldap")
DOCKER_TARGETS=( "${DOCKER_TARGET:-"${DEFAULT_DOCKER_TARGETS[@]}"}")
echo "🏭 Building the following targets:" "${DOCKER_TARGETS[@]}"

###
# Build each target
###
for DOCKER_TARGET in "${DOCKER_TARGETS[@]}"; do
  echo "🏗 Building the target '$DOCKER_TARGET'"

  ###
  # composing the final DOCKER_TAG
  ###
  DOCKER_TAG="${DOCKER_TAG-${DOCKER_ORG}/${DOCKER_REPO}:${TAG}}"
  if [ "$DOCKER_TARGET" != "main" ]; then
    DOCKER_TAG="${DOCKER_TAG}-${DOCKER_TARGET}"
  fi

  ###
  # composing the additional DOCKER_SHORT_TAG,
  # i.e. "v2.6.1" becomes "v2.6",
  # which is only relevant for version tags
  ###
  if [[ "${TAG}" =~ ^v([0-9]+)\.([0-9]+)\.[0-9]+$ ]]; then
    MAJOR=${BASH_REMATCH[1]}
    MINOR=${BASH_REMATCH[2]}

    DOCKER_SHORT_TAG="${DOCKER_SHORT_TAG-${DOCKER_ORG}/${DOCKER_REPO}:v${MAJOR}.${MINOR}}"

    if [ "$DOCKER_TARGET" != "main" ]; then
      DOCKER_SHORT_TAG="${DOCKER_SHORT_TAG}-${DOCKER_TARGET}"
    fi
  fi

  ###
  # Composing global Docker CLI arguments
  ###
  DOCKER_OPTS=("${DOCKER_OPTS[@]}")

  # caching is only ok for version tags,
  # but turning the cache off is only required for the
  # first build target, usually "main".
  case "${TAG}" in
  v*) ;;
  *)  [ "$DOCKER_TARGET" == "${DOCKER_TARGETS[0]}" ] && DOCKER_OPTS+=( --no-cache ) ;;
  esac

  DOCKER_OPTS+=( --pull )
  DOCKER_OPTS+=( --target "$DOCKER_TARGET" )

  ###
  # Composing arguments for `docker build` CLI
  ###
  DOCKER_BUILD_ARGS=(
    --build-arg "NETBOX_DOCKER_PROJECT_VERSION=${NETBOX_DOCKER_PROJECT_VERSION}"
    --build-arg "BRANCH=${BRANCH}"
    --build-arg "URL=${URL}"
    --build-arg "DOCKER_ORG=${DOCKER_ORG}"
    --build-arg "DOCKER_REPO=${DOCKER_REPO}"
  )
  if [ -n "$DOCKER_FROM" ]; then
    DOCKER_BUILD_ARGS+=( --build-arg "FROM=${DOCKER_FROM}" )
  fi
  if [ -n "$HTTP_PROXY" ]; then
    DOCKER_BUILD_ARGS+=( --build-arg "http_proxy=${HTTP_PROXY}" )
  fi
  if [ -n "$HTTPS_PROXY" ]; then
    DOCKER_BUILD_ARGS+=( --build-arg "https_proxy=${HTTPS_PROXY}" )
  fi
  if [ -n "$FTP_PROXY" ]; then
    DOCKER_BUILD_ARGS+=( --build-arg "ftp_proxy=${FTP_PROXY}" )
  fi
  if [ -n "$NO_PROXY" ]; then
    DOCKER_BUILD_ARGS+=( --build-arg "no_proxy=${NO_PROXY}" )
  fi

  ###
  # Determining the build command to use
  ###
  if [ -z "$DRY_RUN" ]; then
    DOCKER_CMD="docker"
  else
    echo "⚠️ DRY_RUN MODE ON ⚠️"
    DOCKER_CMD="echo docker"
  fi

  ###
  # Building the docker images, except if `--push-only` is passed
  ###
  if [ "${2}" != "--push-only" ] ; then
    echo "🐳 Building the Docker image '${DOCKER_TAG}' from the url '${URL}'."
    $DOCKER_CMD build -t "${DOCKER_TAG}" "${DOCKER_BUILD_ARGS[@]}" "${DOCKER_OPTS[@]}" -f "${DOCKERFILE}" .
    echo "✅ Finished building the Docker images '${DOCKER_TAG}'"

    if [ -n "$DOCKER_SHORT_TAG" ]; then
      echo "🐳 Tagging image '${DOCKER_SHORT_TAG}'."
      $DOCKER_CMD tag "${DOCKER_TAG}" "${DOCKER_SHORT_TAG}"
      echo "✅ Tagged image '${DOCKER_SHORT_TAG}'"
    fi
  fi

  ###
  # Pushing the docker images if either `--push` or `--push-only` are passed
  ###
  if [ "${2}" == "--push" ] || [ "${2}" == "--push-only" ] ; then
    echo "⏫ Pushing '${DOCKER_TAG}"
    $DOCKER_CMD push "${DOCKER_TAG}"
    echo "✅ Finished pushing the Docker image '${DOCKER_TAG}'."

    if [ -n "$DOCKER_SHORT_TAG" ]; then
      echo "⏫ Pushing '${DOCKER_SHORT_TAG}'"
      $DOCKER_CMD push "${DOCKER_SHORT_TAG}"
      echo "✅ Finished pushing the Docker image '${DOCKER_SHORT_TAG}'."
    fi
  fi
done
