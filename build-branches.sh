#!/bin/bash
# Builds all published branches

ORIGINAL_GITHUB_REPO="digitalocean/netbox"
GITHUB_REPO="${GITHUB_REPO-$ORIGINAL_GITHUB_REPO}"
URL_RELEASES="https://api.github.com/repos/${GITHUB_REPO}/branches"

CURL="curl -sS"

BRANCHES=$($CURL "${URL_RELEASES}" | jq -r 'map(.name) | .[] | scan("^[^v].+")')

for BRANCH in $BRANCHES; do
  # shellcheck disable=SC2068
  ./build.sh "${BRANCH}" $@
  exit $?
done
