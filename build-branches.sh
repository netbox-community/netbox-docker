#!/bin/bash

ORIGINAL_GITHUB_REPO="digitalocean/netbox"
GITHUB_REPO="${GITHUB_REPO-$ORIGINAL_GITHUB_REPO}"
URL_RELEASES="https://api.github.com/repos/${GITHUB_REPO}/branches"

CURL_OPTS="-s"
CURL="curl ${CURL_OPTS}"

BRANCHES=$($CURL "${URL_RELEASES}" | jq -r 'map(.name) | .[] | scan("^[^v].+")')

VARIANTS=( "ldap" )

for BRANCH in $BRANCHES; do
  ./build.sh "${BRANCH}" $@
  for var in "${VARIANTS[@]}" ; do
    VARIANT=$var ./build.sh "${BRANCH}" $@
  done
done
