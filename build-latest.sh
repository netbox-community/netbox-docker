#!/bin/bash
# Builds the latest released version

echo "▶️ $0 $*"

###
# Check for the jq library needed for parsing JSON
###
if ! command -v jq; then
  echo "⚠️  jq command missing from \$PATH!"
  exit 1
fi

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

  if {
    [ "${MAJOR_STABLE}" -eq "${MAJOR_UNSTABLE}" ] &&
      [ "${MINOR_STABLE}" -ge "${MINOR_UNSTABLE}" ]
  } || [ "${MAJOR_STABLE}" -gt "${MAJOR_UNSTABLE}" ]; then

    echo "❎ Latest unstable version '${VERSION}' is not higher than the latest stable version '$STABLE_VERSION'."
    if [ -z "$DEBUG" ]; then
      if [ -n "${GH_ACTION}" ]; then
        echo "::set-output name=skipped::true"
      fi

      exit 0
    else
      echo "⚠️ Would exit here with code '0', but DEBUG is enabled."
    fi
  fi
fi

# shellcheck disable=SC2068
./build.sh "${VERSION}" $@
exit $?
