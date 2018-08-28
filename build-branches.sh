#!/bin/bash
# Builds develop, develop-* and master branches

echo "▶️ $0 $*"

if [ ! -z "${GITHUB_OAUTH_CLIENT_ID}" ] && [ ! -z "${GITHUB_OAUTH_CLIENT_SECRET}" ]; then
  echo "🗝 Performing authenticated Github API calls."
  GITHUB_OAUTH_PARAMS="client_id=${GITHUB_OAUTH_CLIENT_ID}&client_secret=${GITHUB_OAUTH_CLIENT_SECRET}"
else
  echo "🕶 Performing unauthenticated Github API calls. This might result in lower Github rate limits!"
  GITHUB_OAUTH_PARAMS=""
fi

ORIGINAL_GITHUB_REPO="digitalocean/netbox"
GITHUB_REPO="${GITHUB_REPO-$ORIGINAL_GITHUB_REPO}"
URL_RELEASES="https://api.github.com/repos/${GITHUB_REPO}/branches?${GITHUB_OAUTH_PARAMS}"

CURL="curl -sS"

BRANCHES=$($CURL "${URL_RELEASES}" | jq -r 'map(.name) | .[] | scan("^[^v].+") | match("^(master|develop).*") | .string')

ERROR=0

for BRANCH in $BRANCHES; do
  # shellcheck disable=SC2068
  ./build.sh "${BRANCH}" $@ || ERROR=1
done
exit $ERROR
