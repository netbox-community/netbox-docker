#!/bin/bash
# Clones the Netbox repository with git from Github and builds the Dockerfile

echo "▶️ $0 $*"

set -e

if [ "${1}x" == "x" ] || [ "${1}" == "--help" ] || [ "${1}" == "-h" ]; then
  echo "Usage: ${0} <branch> [--push|--push-only]"
  echo "  branch       The branch or tag to build. Required."
  echo "  --push       Pushes the built Docker image to the registry."
  echo "  --push-only  Only pushes the Docker image to the registry, but does not build it."
  echo ""
  echo "You can use the following ENV variables to customize the build:"
  echo "  SRC_ORG     Which fork of netbox to use (i.e. github.com/\${SRC_ORG}/\${SRC_REPO})."
  echo "              Default: netbox-community"
  echo "  SRC_REPO    The name of the repository to use (i.e. github.com/\${SRC_ORG}/\${SRC_REPO})."
  echo "              Default: netbox"
  echo "  URL         Where to fetch the code from."
  echo "              Must be a git repository. Can be private."
  echo "              Default: https://github.com/\${SRC_ORG}/\${SRC_REPO}.git"
  echo "  NETBOX_PATH The path where netbox will be checkout out."
  echo "              Must not be outside of the netbox-docker repository (because of Docker)!"
  echo "              Default: .netbox"
  echo "  SKIP_GIT    If defined, git is not invoked and \${NETBOX_PATH} will not be altered."
  echo "              This may be useful, if you are manually managing the NETBOX_PATH."
  echo "              Default: undefined"
  echo "  TAG         The version part of the docker tag."
  echo "              Default:"
  echo "                When <branch>=master:  latest"
  echo "                When <branch>=develop: snapshot"
  echo "                Else:                  same as <branch>"
  echo "  DOCKER_REGISTRY The Docker repository's registry (i.e. '\${DOCKER_REGISTRY}/\${DOCKER_ORG}/\${DOCKER_REPO}'')"
  echo "              Used for tagging the image."
  echo "              Default: docker.io"
  echo "  DOCKER_ORG  The Docker repository's organisation (i.e. '\${DOCKER_REGISTRY}/\${DOCKER_ORG}/\${DOCKER_REPO}'')"
  echo "              Used for tagging the image."
  echo "              Default: netboxcommunity"
  echo "  DOCKER_REPO The Docker repository's name (i.e. '\${DOCKER_REGISTRY}/\${DOCKER_ORG}/\${DOCKER_REPO}'')"
  echo "              Used for tagging the image."
  echo "              Default: netbox"
  echo "  DOCKER_TAG  The name of the tag which is applied to the image."
  echo "              Useful for pushing into another registry than hub.docker.com."
  echo "              Default: \${DOCKER_REGISTRY}/\${DOCKER_ORG}/\${DOCKER_REPO}:\${TAG}"
  echo "  DOCKER_SHORT_TAG The name of the short tag which is applied to the"
  echo "              image. This is used to tag all patch releases to their"
  echo "              containing version e.g. v2.5.1 -> v2.5"
  echo "              Default: \${DOCKER_REGISTRY}/\${DOCKER_ORG}/\${DOCKER_REPO}:<MAJOR>.<MINOR>"
  echo "  DOCKERFILE  The name of Dockerfile to use."
  echo "              Default: Dockerfile"
  echo "  DOCKER_FROM The base image to use."
  echo "              Default: Whatever is defined as default in the Dockerfile."
  echo "  DOCKER_TARGET A specific target to build."
  echo "              It's currently not possible to pass multiple targets."
  echo "              Default: main ldap"
  echo "  HTTP_PROXY  The proxy to use for http requests."
  echo "              Example: http://proxy.domain.tld:3128"
  echo "              Default: undefined"
  echo "  NO_PROXY    Comma-separated list of domain extensions proxy should not be used for."
  echo "              Example: .domain1.tld,.domain2.tld"
  echo "              Default: undefined"
  echo "  DEBUG       If defined, the script does not stop when certain checks are unsatisfied."
  echo "              Default: undefined"
  echo "  DRY_RUN     Prints all build statements instead of running them."
  echo "              Default: undefined"
  echo "  GH_ACTION   If defined, special 'echo' statements are enabled that set the"
  echo "              following environment variables in Github Actions:"
  echo "              - FINAL_DOCKER_TAG: The final value of the DOCKER_TAG env variable"
  echo "              Default: undefined"
  echo ""
  echo "Examples:"
  echo "  ${0} master"
  echo "              This will fetch the latest 'master' branch, build a Docker Image and tag it"
  echo "              'netboxcommunity/netbox:latest'."
  echo "  ${0} develop"
  echo "              This will fetch the latest 'develop' branch, build a Docker Image and tag it"
  echo "              'netboxcommunity/netbox:snapshot'."
  echo "  ${0} v2.6.6"
  echo "              This will fetch the 'v2.6.6' tag, build a Docker Image and tag it"
  echo "              'netboxcommunity/netbox:v2.6.6' and 'netboxcommunity/netbox:v2.6'."
  echo "  ${0} develop-2.7"
  echo "              This will fetch the 'develop-2.7' branch, build a Docker Image and tag it"
  echo "              'netboxcommunity/netbox:develop-2.7'."
  echo "  SRC_ORG=cimnine ${0} feature-x"
  echo "              This will fetch the 'feature-x' branch from https://github.com/cimnine/netbox.git,"
  echo "              build a Docker Image and tag it 'netboxcommunity/netbox:feature-x'."
  echo "  SRC_ORG=cimnine DOCKER_ORG=cimnine ${0} feature-x"
  echo "              This will fetch the 'feature-x' branch from https://github.com/cimnine/netbox.git,"
  echo "              build a Docker Image and tag it 'cimnine/netbox:feature-x'."

  if [ "${1}x" == "x" ]; then
    exit 1
  else
    exit 0
  fi
fi

###
# Enabling dry-run mode
###
if [ -z "${DRY_RUN}" ]; then
  DRY=""
else
  echo "⚠️ DRY_RUN MODE ON ⚠️"
  DRY="echo"
fi

###
# Variables for fetching the source
###
SRC_ORG="${SRC_ORG-netbox-community}"
SRC_REPO="${SRC_REPO-netbox}"
NETBOX_BRANCH="${1}"
URL="${URL-https://github.com/${SRC_ORG}/${SRC_REPO}.git}"
NETBOX_PATH="${NETBOX_PATH-.netbox}"

###
# Fetching the source
###
if [ "${2}" != "--push-only" ] && [ -z "${SKIP_GIT}" ] ; then
  echo "🌐 Checking out '${NETBOX_BRANCH}' of netbox from the url '${URL}' into '${NETBOX_PATH}'"
  if [ ! -d "${NETBOX_PATH}" ]; then
    $DRY git clone -q --depth 10 -b "${NETBOX_BRANCH}" "${URL}" "${NETBOX_PATH}"
  fi

  (
    $DRY cd "${NETBOX_PATH}"

    if [ -n "${HTTP_PROXY}" ]; then
      git config http.proxy "${HTTP_PROXY}"
    fi

    $DRY git remote set-url origin "${URL}"
    $DRY git fetch -qp --depth 10 origin "${NETBOX_BRANCH}"
    $DRY git checkout -qf FETCH_HEAD
    $DRY git prune
  )
  echo "✅ Checked out netbox"
fi

###
# Determining the value for DOCKERFILE
# and checking whether it exists
###
DOCKERFILE="${DOCKERFILE-Dockerfile}"
if [ ! -f "${DOCKERFILE}" ]; then
  echo "🚨 The Dockerfile ${DOCKERFILE} doesn't exist."

  if [ -z "${DEBUG}" ]; then
    exit 1
  else
    echo "⚠️ Would exit here with code '1', but DEBUG is enabled."
  fi
fi

###
# Variables for labelling the docker image
###
BUILD_DATE="$(date -u '+%Y-%m-%dT%H:%M+00:00')"

if [ -d ".git" ]; then
  GIT_REF="$(git rev-parse HEAD)"
fi

# Read the project version from the `VERSION` file and trim it, see https://stackoverflow.com/a/3232433/172132
PROJECT_VERSION="${PROJECT_VERSION-$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' VERSION)}"

# Get the Git information from the netbox directory
if [ -d "${NETBOX_PATH}/.git" ]; then
  NETBOX_GIT_REF=$(cd ${NETBOX_PATH}; git rev-parse HEAD)
  NETBOX_GIT_BRANCH=$(cd ${NETBOX_PATH}; git rev-parse --abbrev-ref HEAD)
  NETBOX_GIT_URL=$(cd ${NETBOX_PATH}; git remote get-url origin)
fi

###
# Variables for tagging the docker image
###
DOCKER_REGISTRY="${DOCKER_REGISTRY-docker.io}"
DOCKER_ORG="${DOCKER_ORG-netboxcommunity}"
DOCKER_REPO="${DOCKER_REPO-netbox}"
case "${NETBOX_BRANCH}" in
  master)
    TAG="${TAG-latest}";;
  develop)
    TAG="${TAG-snapshot}";;
  *)
    TAG="${TAG-$NETBOX_BRANCH}";;
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
export DOCKER_BUILDKIT=${DOCKER_BUILDKIT-1}
for DOCKER_TARGET in "${DOCKER_TARGETS[@]}"; do
  echo "🏗 Building the target '${DOCKER_TARGET}'"

  ###
  # composing the final TARGET_DOCKER_TAG
  ###
  TARGET_DOCKER_TAG="${DOCKER_TAG-${DOCKER_REGISTRY}/${DOCKER_ORG}/${DOCKER_REPO}:${TAG}}"
  if [ "${DOCKER_TARGET}" != "main" ]; then
    TARGET_DOCKER_TAG="${TARGET_DOCKER_TAG}-${DOCKER_TARGET}"
  fi
  if [ -n "${GH_ACTION}" ]; then
    echo "::set-env name=FINAL_DOCKER_TAG::${TARGET_DOCKER_TAG}"
    echo "::set-output name=skipped::false"
  fi

  ###
  # composing the additional DOCKER_SHORT_TAG,
  # i.e. "v2.6.1" becomes "v2.6",
  # which is only relevant for version tags
  ###
  if [[ "${TAG}" =~ ^v([0-9]+)\.([0-9]+)\.[0-9]+$ ]]; then
    MAJOR=${BASH_REMATCH[1]}
    MINOR=${BASH_REMATCH[2]}

    TARGET_DOCKER_SHORT_TAG="${DOCKER_SHORT_TAG-${DOCKER_REGISTRY}/${DOCKER_ORG}/${DOCKER_REPO}:v${MAJOR}.${MINOR}}"

    if [ "${DOCKER_TARGET}" != "main" ]; then
      TARGET_DOCKER_SHORT_TAG="${TARGET_DOCKER_SHORT_TAG}-${DOCKER_TARGET}"
    fi
  fi

  ###
  # Proceeding to buils stage, except if `--push-only` is passed
  ###
  if [ "${2}" != "--push-only" ] ; then
    ###
    # Composing all arguments for `docker build`
    ###
    DOCKER_BUILD_ARGS=(
      --pull
      --target "${DOCKER_TARGET}"
      -f "${DOCKERFILE}"
      -t "${TARGET_DOCKER_TAG}"
    )
    if [ -n "${TARGET_DOCKER_SHORT_TAG}" ]; then
      DOCKER_BUILD_ARGS+=( -t "${TARGET_DOCKER_SHORT_TAG}" )
    fi

    # --label
    if [ "${DOCKER_TARGET}" == "main" ]; then
      DOCKER_BUILD_ARGS+=(
        --label "ORIGINAL_TAG=${TARGET_DOCKER_TAG}"

        --label "org.label-schema.build-date=${BUILD_DATE}"
        --label "org.opencontainers.image.created=${BUILD_DATE}"

        --label "org.label-schema.version=${PROJECT_VERSION}"
        --label "org.opencontainers.image.version=${PROJECT_VERSION}"
      )
      if [ -d ".git" ]; then
        DOCKER_BUILD_ARGS+=(
          --label "org.label-schema.vcs-ref=${GIT_REF}"
          --label "org.opencontainers.image.revision=${GIT_REF}"
        )
      fi
      if [ -d "${NETBOX_PATH}/.git" ]; then
        DOCKER_BUILD_ARGS+=(
          --label "NETBOX_GIT_BRANCH=${NETBOX_GIT_BRANCH}"
          --label "NETBOX_GIT_REF=${NETBOX_GIT_REF}"
          --label "NETBOX_GIT_URL=${NETBOX_GIT_URL}"
        )
      fi
    fi

    # --build-arg
    DOCKER_BUILD_ARGS+=(   --build-arg "NETBOX_PATH=${NETBOX_PATH}" )

    if [ -n "${DOCKER_FROM}" ]; then
      DOCKER_BUILD_ARGS+=( --build-arg "FROM=${DOCKER_FROM}" )
    fi
    if [ -n "${HTTP_PROXY}" ]; then
      DOCKER_BUILD_ARGS+=( --build-arg "http_proxy=${HTTP_PROXY}" )
      DOCKER_BUILD_ARGS+=( --build-arg "https_proxy=${HTTPS_PROXY}" )
    fi
    if [ -n "${NO_PROXY}" ]; then
      DOCKER_BUILD_ARGS+=( --build-arg "no_proxy=${NO_PROXY}" )
    fi

    ###
    # Building the docker image
    ###
    echo "🐳 Building the Docker image '${TARGET_DOCKER_TAG}'."
    $DRY docker build "${DOCKER_BUILD_ARGS[@]}" .
    echo "✅ Finished building the Docker images '${TARGET_DOCKER_TAG}'"
  fi

  ###
  # Pushing the docker images if either `--push` or `--push-only` are passed
  ###
  if [ "${2}" == "--push" ] || [ "${2}" == "--push-only" ] ; then
    echo "⏫ Pushing '${TARGET_DOCKER_TAG}"
    $DRY docker push "${TARGET_DOCKER_TAG}"
    echo "✅ Finished pushing the Docker image '${TARGET_DOCKER_TAG}'."

    if [ -n "${TARGET_DOCKER_SHORT_TAG}" ]; then
      echo "⏫ Pushing '${TARGET_DOCKER_SHORT_TAG}'"
      $DRY docker push "${TARGET_DOCKER_SHORT_TAG}"
      echo "✅ Finished pushing the Docker image '${TARGET_DOCKER_SHORT_TAG}'."
    fi
  fi
done
