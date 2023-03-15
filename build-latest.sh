#!/bin/bash
# Builds the latest released version

# Check if we have everything needed for the build
source ./build-functions/check-commands.sh

source ./build-functions/gh-functions.sh

echo "▶️ $0 $*"

CURL_ARGS=(
  --silent
)

###
# Checking for the presence of GITHUB_TOKEN
###
if [ -n "${GITHUB_TOKEN}" ]; then
  echo "🗝 Performing authenticated Github API calls."
  CURL_ARGS+=(
    --header "Authorization: Bearer ${GITHUB_TOKEN}"
  )
else
  echo "🕶 Performing unauthenticated Github API calls. This might result in lower Github rate limits!"
fi

###
# Checking if PRERELEASE is either unset, 'true' or 'false'
###
if [ -n "${PRERELEASE}" ] &&
  { [ "${PRERELEASE}" != "true" ] && [ "${PRERELEASE}" != "false" ]; }; then

  if [ -z "${DEBUG}" ]; then
    echo "⚠️ PRERELEASE must be either unset, 'true' or 'false', but was '${PRERELEASE}'!"
    exit 1
  else
    echo "⚠️ Would exit here with code '1', but DEBUG is enabled."
  fi
fi

###
# Calling Github to get the latest version
###
ORIGINAL_GITHUB_REPO="netbox-community/netbox"
GITHUB_REPO="${GITHUB_REPO-$ORIGINAL_GITHUB_REPO}"
URL_RELEASES="https://api.github.com/repos/${GITHUB_REPO}/releases"

# Composing the JQ commans to extract the most recent version number
JQ_LATEST="group_by(.prerelease) | .[] | sort_by(.published_at) | reverse | .[0] | select(.prerelease==${PRERELEASE-false}) | .tag_name"

CURL="curl"

# Querying the Github API to fetch the most recent version number
VERSION=$($CURL "${CURL_ARGS[@]}" "${URL_RELEASES}" | jq -r "${JQ_LATEST}" 2>/dev/null)

###
# Check if the prerelease version is actually higher than stable version
###
if [ "${PRERELEASE}" == "true" ]; then
  JQ_STABLE="group_by(.prerelease) | .[] | sort_by(.published_at) | reverse | .[0] | select(.prerelease==false) | .tag_name"
  STABLE_VERSION=$($CURL "${CURL_ARGS[@]}" "${URL_RELEASES}" | jq -r "${JQ_STABLE}" 2>/dev/null)

  MAJOR_STABLE=$(expr "${STABLE_VERSION}" : 'v\([0-9]\+\)')
  MINOR_STABLE=$(expr "${STABLE_VERSION}" : 'v[0-9]\+\.\([0-9]\+\)')
  MAJOR_UNSTABLE=$(expr "${VERSION}" : 'v\([0-9]\+\)')
  MINOR_UNSTABLE=$(expr "${VERSION}" : 'v[0-9]\+\.\([0-9]\+\)')

  if {
    [ "${MAJOR_STABLE}" -eq "${MAJOR_UNSTABLE}" ] &&
      [ "${MINOR_STABLE}" -ge "${MINOR_UNSTABLE}" ]
  } || [ "${MAJOR_STABLE}" -gt "${MAJOR_UNSTABLE}" ]; then

    echo "❎ Latest unstable version '${VERSION}' is not higher than the latest stable version '$STABLE_VERSION'."
    if [ -z "$DEBUG" ]; then
      gh_out "skipped=true"
      exit 0
    else
      echo "⚠️ Would exit here with code '0', but DEBUG is enabled."
    fi
  fi
fi

# shellcheck disable=SC2068
./build.sh "${VERSION}" $@
exit $?
