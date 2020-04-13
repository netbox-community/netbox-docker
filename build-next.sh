#!/bin/bash
# Builds develop, develop-* and master branches of Netbox

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
# Calling Github to get the all branches
###
ORIGINAL_GITHUB_REPO="${SRC_ORG-netbox-community}/${SRC_REPO-netbox}"
GITHUB_REPO="${GITHUB_REPO-$ORIGINAL_GITHUB_REPO}"
URL_RELEASES="https://api.github.com/repos/${GITHUB_REPO}/branches?${GITHUB_OAUTH_PARAMS}"

# Composing the JQ commans to extract the most recent version number
JQ_NEXT='map(.name) | .[] | scan("^[^v].+") | match("^(develop-).*") | .string'

CURL="curl -sS"

# Querying the Github API to fetch all branches
NEXT=$($CURL "${URL_RELEASES}" | jq -r "$JQ_NEXT")

if [ -n "$NEXT" ]; then
  # shellcheck disable=SC2068
  ./build.sh "${NEXT}" $@
else
  echo "No branch matching 'develop-*' found"
  echo "::set-output name=skipped::true"
fi
