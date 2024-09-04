#!/bin/bash
# Clones the NetBox repository with git from Github and builds the Dockerfile

echo "▶️ $0 $*"

set -e

if [ "${1}x" == "x" ] || [ "${1}" == "--help" ] || [ "${1}" == "-h" ]; then
  _BOLD=$(tput bold)
  _GREEN=$(tput setaf 2)
  _CYAN=$(tput setaf 6)
  _CLEAR=$(tput sgr0)

  cat <<END_OF_HELP
${_BOLD}Usage:${_CLEAR} ${0} <branch> [--push]

branch       The branch or tag to build. Required.
--push       Pushes the built container image to the registry.

${_BOLD}You can use the following ENV variables to customize the build:${_CLEAR}

SRC_ORG     Which fork of netbox to use (i.e. github.com/\${SRC_ORG}/\${SRC_REPO}).
            ${_GREEN}Default:${_CLEAR} netbox-community
            
SRC_REPO    The name of the repository to use (i.e. github.com/\${SRC_ORG}/\${SRC_REPO}).
            ${_GREEN}Default:${_CLEAR} netbox
            
URL         Where to fetch the code from.
            Must be a git repository. Can be private.
            ${_GREEN}Default:${_CLEAR} https://github.com/\${SRC_ORG}/\${SRC_REPO}.git

NETBOX_PATH The path where netbox will be checkout out.
            Must not be outside of the netbox-docker repository (because of Docker)!
            ${_GREEN}Default:${_CLEAR} .netbox

SKIP_GIT    If defined, git is not invoked and \${NETBOX_PATH} will not be altered.
            This may be useful, if you are manually managing the NETBOX_PATH.
            ${_GREEN}Default:${_CLEAR} undefined

TAG         The version part of the image tag.
            ${_GREEN}Default:${_CLEAR}
              When <branch>=master:  latest
              When <branch>=develop: snapshot
              Else:                  same as <branch>

IMAGE_NAMES The names used for the image including the registry
            Used for tagging the image.
            ${_GREEN}Default:${_CLEAR} docker.io/netboxcommunity/netbox
            ${_CYAN}Example:${_CLEAR} 'docker.io/netboxcommunity/netbox quay.io/netboxcommunity/netbox'

DOCKER_TAG  The name of the tag which is applied to the image.
            Useful for pushing into another registry than hub.docker.com.
            ${_GREEN}Default:${_CLEAR} \${DOCKER_REGISTRY}/\${DOCKER_ORG}/\${DOCKER_REPO}:\${TAG}

DOCKER_SHORT_TAG The name of the short tag which is applied to the
            image. This is used to tag all patch releases to their
            containing version e.g. v2.5.1 -> v2.5
            ${_GREEN}Default:${_CLEAR} \${DOCKER_REGISTRY}/\${DOCKER_ORG}/\${DOCKER_REPO}:<MAJOR>.<MINOR>

DOCKERFILE  The name of Dockerfile to use.
            ${_GREEN}Default:${_CLEAR} Dockerfile

DOCKER_FROM The base image to use.
            ${_GREEN}Default:${_CLEAR} 'ubuntu:24.04'

BUILDX_PLATFORMS
            Specifies the platform(s) to build the image for.
            ${_CYAN}Example:${_CLEAR} 'linux/amd64,linux/arm64'
            ${_GREEN}Default:${_CLEAR} 'linux/amd64'

BUILDX_BUILDER_NAME
            If defined, the image build will be assigned to the given builder.
            If you specify this variable, make sure that the builder exists.
            If this value is not defined, a new builx builder with the directory name of the
            current directory (i.e. '$(basename "${PWD}")') is created."
            ${_CYAN}Example:${_CLEAR} 'clever_lovelace'
            ${_GREEN}Default:${_CLEAR} undefined

BUILDX_REMOVE_BUILDER
            If defined (and only if BUILDX_BUILDER_NAME is undefined),
            then the buildx builder created by this script will be removed after use.
            This is useful if you build NetBox Docker on an automated system that does
            not manage the builders for you.
            ${_CYAN}Example:${_CLEAR} 'on'
            ${_GREEN}Default:${_CLEAR} undefined

HTTP_PROXY  The proxy to use for http requests.
            ${_CYAN}Example:${_CLEAR} http://proxy.domain.tld:3128
            ${_GREEN}Default:${_CLEAR} undefined

NO_PROXY    Comma-separated list of domain extensions proxy should not be used for.
            ${_CYAN}Example:${_CLEAR} .domain1.tld,.domain2.tld
            ${_GREEN}Default:${_CLEAR} undefined

DEBUG       If defined, the script does not stop when certain checks are unsatisfied.
            ${_GREEN}Default:${_CLEAR} undefined

DRY_RUN     Prints all build statements instead of running them.
            ${_GREEN}Default:${_CLEAR} undefined
            
GH_ACTION   If defined, special 'echo' statements are enabled that set the
            following environment variables in Github Actions:
            - FINAL_DOCKER_TAG: The final value of the DOCKER_TAG env variable
            ${_GREEN}Default:${_CLEAR} undefined

CHECK_ONLY  Only checks if the build is needed and sets the GH Action output.

${_BOLD}Examples:${_CLEAR}

${0} master
            This will fetch the latest 'master' branch, build a Docker Image and tag it
            'netboxcommunity/netbox:latest'.

${0} develop
            This will fetch the latest 'develop' branch, build a Docker Image and tag it
            'netboxcommunity/netbox:snapshot'.

${0} v2.6.6
            This will fetch the 'v2.6.6' tag, build a Docker Image and tag it
            'netboxcommunity/netbox:v2.6.6' and 'netboxcommunity/netbox:v2.6'.

${0} develop-2.7
            This will fetch the 'develop-2.7' branch, build a Docker Image and tag it
            'netboxcommunity/netbox:develop-2.7'.

SRC_ORG=cimnine ${0} feature-x
            This will fetch the 'feature-x' branch from https://github.com/cimnine/netbox.git,
            build a Docker Image and tag it 'netboxcommunity/netbox:feature-x'.

SRC_ORG=cimnine DOCKER_ORG=cimnine ${0} feature-x
            This will fetch the 'feature-x' branch from https://github.com/cimnine/netbox.git,
            build a Docker Image and tag it 'cimnine/netbox:feature-x'.
END_OF_HELP

  if [ "${1}x" == "x" ]; then
    exit 1
  else
    exit 0
  fi
fi

# Check if we have everything needed for the build
source ./build-functions/check-commands.sh
# Load all build functions
source ./build-functions/get-public-image-config.sh
source ./build-functions/gh-functions.sh

IMAGE_NAMES="${IMAGE_NAMES-docker.io/netboxcommunity/netbox}"
IFS=' ' read -ra IMAGE_NAMES <<<"${IMAGE_NAMES}"

###
# Enabling dry-run mode
###
if [ -z "${DRY_RUN}" ]; then
  DRY=""
else
  echo "⚠️ DRY_RUN MODE ON ⚠️"
  DRY="echo"
fi

gh_echo "::group::⤵️ Fetching the NetBox source code"

###
# Variables for fetching the NetBox source
###
SRC_ORG="${SRC_ORG-netbox-community}"
SRC_REPO="${SRC_REPO-netbox}"
NETBOX_BRANCH="${1}"
URL="${URL-https://github.com/${SRC_ORG}/${SRC_REPO}.git}"
NETBOX_PATH="${NETBOX_PATH-.netbox}"

###
# Fetching the NetBox source
###
if [ "${2}" != "--push-only" ] && [ -z "${SKIP_GIT}" ]; then
  REMOTE_EXISTS=$(git ls-remote --heads --tags "${URL}" "${NETBOX_BRANCH}" | wc -l)
  if [ "${REMOTE_EXISTS}" == "0" ]; then
    echo "❌ Remote branch '${NETBOX_BRANCH}' not found in '${URL}'; Nothing to do"
    gh_out "skipped=true"
    exit 0
  fi
  echo "🌐 Checking out '${NETBOX_BRANCH}' of NetBox from the url '${URL}' into '${NETBOX_PATH}'"
  if [ ! -d "${NETBOX_PATH}" ]; then
    $DRY git clone -q --depth 10 -b "${NETBOX_BRANCH}" "${URL}" "${NETBOX_PATH}"
  fi

  (
    $DRY cd "${NETBOX_PATH}"
    # shellcheck disable=SC2030
    if [ -n "${HTTP_PROXY}" ]; then
      git config http.proxy "${HTTP_PROXY}"
    fi

    $DRY git remote set-url origin "${URL}"
    $DRY git fetch -qp --depth 10 origin "${NETBOX_BRANCH}"
    $DRY git checkout -qf FETCH_HEAD
    $DRY git prune
  )
  echo "✅ Checked out NetBox"
fi

gh_echo "::endgroup::"
gh_echo "::group::🧮 Calculating Values"

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
# Determining the value for DOCKER_FROM
###
if [ -z "$DOCKER_FROM" ]; then
  DOCKER_FROM="docker.io/ubuntu:24.04"
fi

###
# Variables for labelling the docker image
###
BUILD_DATE="$(date -u '+%Y-%m-%dT%H:%M+00:00')"

if [ -d ".git" ] && [ -z "${SKIP_GIT}" ]; then
  GIT_REF="$(git rev-parse HEAD)"
fi

# Read the project version from the `VERSION` file and trim it, see https://stackoverflow.com/a/3232433/172132
PROJECT_VERSION="${PROJECT_VERSION-$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' VERSION)}"

# Get the Git information from the netbox directory
if [ -d "${NETBOX_PATH}/.git" ] && [ -z "${SKIP_GIT}" ]; then
  NETBOX_GIT_REF=$(
    cd "${NETBOX_PATH}"
    git rev-parse HEAD
  )
  NETBOX_GIT_BRANCH=$(
    cd "${NETBOX_PATH}"
    git rev-parse --abbrev-ref HEAD
  )
  NETBOX_GIT_URL=$(
    cd "${NETBOX_PATH}"
    git remote get-url origin
  )
fi

###
# Variables for tagging the docker image
###
DOCKER_REGISTRY="${DOCKER_REGISTRY-docker.io}"
DOCKER_ORG="${DOCKER_ORG-netboxcommunity}"
DOCKER_REPO="${DOCKER_REPO-netbox}"
case "${NETBOX_BRANCH}" in
master)
  TAG="${TAG-latest}"
  ;;
develop)
  TAG="${TAG-snapshot}"
  ;;
*)
  TAG="${TAG-$NETBOX_BRANCH}"
  ;;
esac

###
# composing the final TARGET_DOCKER_TAG
###
TARGET_DOCKER_TAG="${DOCKER_TAG-${TAG}}"
TARGET_DOCKER_TAG_PROJECT="${TARGET_DOCKER_TAG}-${PROJECT_VERSION}"

###
# composing the additional DOCKER_SHORT_TAG,
# i.e. "v2.6.1" becomes "v2.6",
# which is only relevant for version tags
# Also let "latest" follow the highest version
###
if [[ "${TAG}" =~ ^v([0-9]+)\.([0-9]+)\.[0-9]+$ ]]; then
  MAJOR=${BASH_REMATCH[1]}
  MINOR=${BASH_REMATCH[2]}

  TARGET_DOCKER_SHORT_TAG="${DOCKER_SHORT_TAG-v${MAJOR}.${MINOR}}"
  TARGET_DOCKER_LATEST_TAG="latest"
  TARGET_DOCKER_SHORT_TAG_PROJECT="${TARGET_DOCKER_SHORT_TAG}-${PROJECT_VERSION}"
  TARGET_DOCKER_LATEST_TAG_PROJECT="${TARGET_DOCKER_LATEST_TAG}-${PROJECT_VERSION}"
fi

IMAGE_NAME_TAGS=()
for IMAGE_NAME in "${IMAGE_NAMES[@]}"; do
  IMAGE_NAME_TAGS+=("${IMAGE_NAME}:${TARGET_DOCKER_TAG}")
  IMAGE_NAME_TAGS+=("${IMAGE_NAME}:${TARGET_DOCKER_TAG_PROJECT}")
done
if [ -n "${TARGET_DOCKER_SHORT_TAG}" ]; then
  for IMAGE_NAME in "${IMAGE_NAMES[@]}"; do
    IMAGE_NAME_TAGS+=("${IMAGE_NAME}:${TARGET_DOCKER_SHORT_TAG}")
    IMAGE_NAME_TAGS+=("${IMAGE_NAME}:${TARGET_DOCKER_SHORT_TAG_PROJECT}")
    IMAGE_NAME_TAGS+=("${IMAGE_NAME}:${TARGET_DOCKER_LATEST_TAG}")
    IMAGE_NAME_TAGS+=("${IMAGE_NAME}:${TARGET_DOCKER_LATEST_TAG_PROJECT}")
  done
fi

FINAL_DOCKER_TAG="${IMAGE_NAME_TAGS[0]}"
gh_env "FINAL_DOCKER_TAG=${IMAGE_NAME_TAGS[0]}"

###
# Checking if the build is necessary,
# meaning build only if one of those values changed:
# - a new tag is beeing created
# - base image digest
# - netbox git ref (Label: netbox.git-ref)
# - netbox-docker git ref (Label: org.opencontainers.image.revision)
###
# Load information from registry (only for first registry in "IMAGE_NAMES")
SHOULD_BUILD="false"
BUILD_REASON=""
if [ -z "${GH_ACTION}" ]; then
  # Asuming non Github builds should always proceed
  SHOULD_BUILD="true"
  BUILD_REASON="${BUILD_REASON} interactive"
elif [ "false" == "$(check_if_tags_exists "${IMAGE_NAMES[0]}" "$TARGET_DOCKER_TAG")" ]; then
  SHOULD_BUILD="true"
  BUILD_REASON="${BUILD_REASON} newtag"
else
  echo "Checking labels for '${FINAL_DOCKER_TAG}'"
  BASE_LAST_LAYER=$(get_image_last_layer "${DOCKER_FROM}")
  OLD_BASE_LAST_LAYER=$(get_image_label netbox.last-base-image-layer "${FINAL_DOCKER_TAG}")
  NETBOX_GIT_REF_OLD=$(get_image_label netbox.git-ref "${FINAL_DOCKER_TAG}")
  GIT_REF_OLD=$(get_image_label org.opencontainers.image.revision "${FINAL_DOCKER_TAG}")

  if [ "${BASE_LAST_LAYER}" != "${OLD_BASE_LAST_LAYER}" ]; then
    SHOULD_BUILD="true"
    BUILD_REASON="${BUILD_REASON} ubuntu"
  fi
  if [ "${NETBOX_GIT_REF}" != "${NETBOX_GIT_REF_OLD}" ]; then
    SHOULD_BUILD="true"
    BUILD_REASON="${BUILD_REASON} netbox"
  fi
  if [ "${GIT_REF}" != "${GIT_REF_OLD}" ]; then
    SHOULD_BUILD="true"
    BUILD_REASON="${BUILD_REASON} netbox-docker"
  fi
fi

if [ "${SHOULD_BUILD}" != "true" ]; then
  echo "Build skipped because sources didn't change"
  gh_out "skipped=true"
  exit 0 # Nothing to do -> exit
else
  gh_out "skipped=false"
fi
gh_echo "::endgroup::"

if [ "${CHECK_ONLY}" = "true" ]; then
  echo "Only check if build needed was requested. Exiting"
  exit 0
fi

###
# Build the image
###
gh_echo "::group::🏗 Building the image"
###
# Composing all arguments for `docker build`
###
DOCKER_BUILD_ARGS=(
  --pull
  --target main
  -f "${DOCKERFILE}"
)
for IMAGE_NAME in "${IMAGE_NAME_TAGS[@]}"; do
  DOCKER_BUILD_ARGS+=(-t "${IMAGE_NAME}")
done

# --label
DOCKER_BUILD_ARGS+=(
  --label "netbox.original-tag=${TARGET_DOCKER_TAG_PROJECT}"
  --label "org.opencontainers.image.created=${BUILD_DATE}"
  --label "org.opencontainers.image.version=${PROJECT_VERSION}"
)
if [ -d ".git" ] && [ -z "${SKIP_GIT}" ]; then
  DOCKER_BUILD_ARGS+=(
    --label "org.opencontainers.image.revision=${GIT_REF}"
  )
fi
if [ -d "${NETBOX_PATH}/.git" ] && [ -z "${SKIP_GIT}" ]; then
  DOCKER_BUILD_ARGS+=(
    --label "netbox.git-branch=${NETBOX_GIT_BRANCH}"
    --label "netbox.git-ref=${NETBOX_GIT_REF}"
    --label "netbox.git-url=${NETBOX_GIT_URL}"
  )
fi
if [ -n "${BUILD_REASON}" ]; then
  BUILD_REASON=$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<<"$BUILD_REASON")
  DOCKER_BUILD_ARGS+=(--label "netbox.build-reason=${BUILD_REASON}")
  DOCKER_BUILD_ARGS+=(--label "netbox.last-base-image-layer=${BASE_LAST_LAYER}")
fi

# --build-arg
DOCKER_BUILD_ARGS+=(--build-arg "NETBOX_PATH=${NETBOX_PATH}")

if [ -n "${DOCKER_FROM}" ]; then
  DOCKER_BUILD_ARGS+=(--build-arg "FROM=${DOCKER_FROM}")
fi
# shellcheck disable=SC2031
if [ -n "${HTTP_PROXY}" ]; then
  DOCKER_BUILD_ARGS+=(--build-arg "http_proxy=${HTTP_PROXY}")
  DOCKER_BUILD_ARGS+=(--build-arg "https_proxy=${HTTPS_PROXY}")
fi
if [ -n "${NO_PROXY}" ]; then
  DOCKER_BUILD_ARGS+=(--build-arg "no_proxy=${NO_PROXY}")
fi

DOCKER_BUILD_ARGS+=(--platform "${BUILDX_PLATFORM-linux/amd64}")
if [ "${2}" == "--push" ]; then
  # output type=docker does not work with pushing
  DOCKER_BUILD_ARGS+=(
    --output=type=image
    --push
  )
else
  DOCKER_BUILD_ARGS+=(
    --output=type=docker
  )
fi

###
# Building the docker image
###
if [ -z "${BUILDX_BUILDER_NAME}" ]; then
  BUILDX_BUILDER_NAME="$(basename "${PWD}")"
fi
if ! docker buildx ls | grep --quiet --word-regexp "${BUILDX_BUILDER_NAME}"; then
  echo "👷  Creating new Buildx Builder '${BUILDX_BUILDER_NAME}'"
  $DRY docker buildx create --name "${BUILDX_BUILDER_NAME}"
  BUILDX_BUILDER_CREATED="yes"
fi

echo "🐳 Building the Docker image '${TARGET_DOCKER_TAG_PROJECT}'."
echo "    Build reason set to: ${BUILD_REASON}"
$DRY docker buildx \
  --builder "${BUILDX_BUILDER_NAME}" \
  build \
  "${DOCKER_BUILD_ARGS[@]}" \
  .
echo "✅ Finished building the Docker images"
gh_echo "::endgroup::" # End group for Build

gh_echo "::group::🏗 Image Labels"
echo "🔎 Inspecting labels on '${IMAGE_NAME_TAGS[0]}'"
$DRY docker inspect "${IMAGE_NAME_TAGS[0]}" --format "{{json .Config.Labels}}" | jq
gh_echo "::endgroup::"

gh_echo "::group::🏗 Clean up"
if [ -n "${BUILDX_REMOVE_BUILDER}" ] && [ "${BUILDX_BUILDER_CREATED}" == "yes" ]; then
  echo "👷  Removing Buildx Builder '${BUILDX_BUILDER_NAME}'"
  $DRY docker buildx rm "${BUILDX_BUILDER_NAME}"
fi
gh_echo "::endgroup::"
