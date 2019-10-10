#!/bin/bash
# Builds the latest released version

echo "▶️ $0 $*"

###
# Checking for the presence of GITHUB_OAUTH_CLIENT_ID
# and GITHUB_OAUTH_CLIENT_SECRET
###
if [ -n "${GITHUB_OAUTH_CLIENT_ID}" ] && [ -n "${GITHUB_OAUTH_CLIENT_SECRET}" ]; then
  echo "🗝 Performing authenticated Github API calls."
  GITHUB_OAUTH_PARAMS="client_id=${GITHUB_OAUTH_CLIENT_ID}&client_secret=${GITHUB_OAUTH_CLIENT_SECRET}"
else
  echo "🕶 Performing unauthenticated Github API calls. This might result in lower Github rate limits!"
  GITHUB_OAUTH_PARAMS=""
fi

###
# Checking if PRERELEASE is either unset, 'true' or 'false'
###
if [ -n "$PRERELEASE" ] &&
   { [ "$PRERELEASE" != "true" ] && [ "$PRERELEASE" != "false" ]; }; then

  if [ -z "$DEBUG" ]; then
    echo "⚠️ PRERELEASE must be either unset, 'true' or 'false', but was \"$PRERELEASE\"!"
    exit 1
  else
    echo "⚠️ Would exit here with code '0', but DEBUG is enabled."
  fi
fi

###
# Calling Github to get the latest version
###
ORIGINAL_GITHUB_REPO="netbox-community/netbox"
GITHUB_REPO="${GITHUB_REPO-$ORIGINAL_GITHUB_REPO}"
URL_RELEASES="https://api.github.com/repos/${GITHUB_REPO}/releases?${GITHUB_OAUTH_PARAMS}"

# Composing the JQ commans to extract the most recent version number
JQ_LATEST="group_by(.prerelease) | .[] | sort_by(.published_at) | reverse | .[0] | select(.prerelease==${PRERELEASE-false}) | .tag_name"

CURL="curl -sS"

# Querying the Github API to fetch the most recent version number
VERSION=$($CURL "${URL_RELEASES}" | jq -r "${JQ_LATEST}")

###
# Check if the prerelease version is actually higher than stable version
###
if [ "${PRERELEASE}" == "true" ]; then
  JQ_STABLE="group_by(.prerelease) | .[] | sort_by(.published_at) | reverse | .[0] | select(.prerelease==false) | .tag_name"
  STABLE_VERSION=$($CURL "${URL_RELEASES}" | jq -r "${JQ_STABLE}")

  # shellcheck disable=SC2003
  MAJOR_STABLE=$(expr match "${STABLE_VERSION}" 'v\([0-9]\+\)')
  # shellcheck disable=SC2003
  MINOR_STABLE=$(expr match "${STABLE_VERSION}" 'v[0-9]\+\.\([0-9]\+\)')
  # shellcheck disable=SC2003
  MAJOR_UNSTABLE=$(expr match "${VERSION}" 'v\([0-9]\+\)')
  # shellcheck disable=SC2003
  MINOR_UNSTABLE=$(expr match "${VERSION}" 'v[0-9]\+\.\([0-9]\+\)')

  if { [ "$MAJOR_STABLE" -eq "$MAJOR_UNSTABLE" ] && [ "$MINOR_STABLE" -ge "$MINOR_UNSTABLE" ]; } \
     || [ "$MAJOR_STABLE" -gt "$MAJOR_UNSTABLE" ]; then

    echo "❎ Latest unstable version ('$VERSION') is not higher than the latest stable version ('$STABLE_VERSION')."
    if [ -z "$DEBUG" ]; then
      exit 0
    else
      echo "⚠️ Would exit here with code '0', but DEBUG is enabled."
    fi
  fi
fi

###
# Compose DOCKER_TAG to build
###
if [ -z "$DOCKER_TARGET" ] || [ "$DOCKER_TARGET" == "main" ]; then
  DOCKER_TAG="${VERSION}"
else
  DOCKER_TAG="${VERSION}-${DOCKER_TARGET}"
fi

###
# Check if the version received is not already available on Docker Hub:
###
ORIGINAL_DOCKERHUB_REPO="${DOCKER_ORG-netboxcommunity}/${DOCKER_REPO-netbox}"
DOCKERHUB_REPO="${DOCKERHUB_REPO-$ORIGINAL_DOCKERHUB_REPO}"

# Bearer Token
URL_DOCKERHUB_TOKEN="https://auth.docker.io/token?service=registry.docker.io&scope=repository:${DOCKERHUB_REPO}:pull"
BEARER_TOKEN="$($CURL "${URL_DOCKERHUB_TOKEN}" | jq -r .token)"

# Actual API call
URL_DOCKERHUB_TAG="https://registry.hub.docker.com/v2/${DOCKERHUB_REPO}/tags/list"
AUTHORIZATION_HEADER="Authorization: Bearer ${BEARER_TOKEN}"
ALREADY_BUILT="$($CURL -H "${AUTHORIZATION_HEADER}" "${URL_DOCKERHUB_TAG}" | jq -e ".tags | any(.==\"${DOCKER_TAG}\")")"

###
# Only build the image if it's not already been built before
###
if [ -n "$DEBUG" ] || [ "$ALREADY_BUILT" == "false" ]; then
  if [ -n "$DEBUG" ]; then
    echo "⚠️ Would not build, because ${DOCKER_TAG} already exists on https://hub.docker.com/r/${DOCKERHUB_REPO}, but DEBUG is enabled."
  fi

  # shellcheck disable=SC2068
  ./build.sh "${VERSION}" $@
  exit $?
else
  echo "✅ ${DOCKER_TAG} already exists on https://hub.docker.com/r/${DOCKERHUB_REPO}"
  exit 0
fi
