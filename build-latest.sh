#!/bin/bash

URL_RELEASES=https://api.github.com/repos/digitalocean/netbox/releases

JQ_LATEST="group_by(.prerelease) | .[] | sort_by(.published_at) | reverse | .[0] | select(.prerelease==${PRERELEASE-false}) | .tag_name"

CURL_OPTS="-s"

VERSION=$(curl $CURL_OPTS "${URL_RELEASES}" | jq -r "${JQ_LATEST}")

# Check if the prerelease version is actually higher than stable version
if [ "${PRERELEASE}" == "true" ]; then
  JQ_STABLE="group_by(.prerelease) | .[] | sort_by(.published_at) | reverse | .[0] | select(.prerelease==false) | .tag_name"
  STABLE_VERSION=$(curl $CURL_OPTS "${URL_RELEASES}" | jq -r "${JQ_STABLE}")

  MAJOR_STABLE=$(expr match "${STABLE_VERSION}" 'v\([0-9]\+\)')
  MINOR_STABLE=$(expr match "${STABLE_VERSION}" 'v[0-9]\+\.\([0-9]\+\)')
  MAJOR_UNSTABLE=$(expr match "${VERSION}" 'v\([0-9]\+\)')
  MINOR_UNSTABLE=$(expr match "${VERSION}" 'v[0-9]\+\.\([0-9]\+\)')

  if ( [ "$MAJOR_STABLE" -eq "$MAJOR_UNSTABLE" ] && [ "$MINOR_STABLE" -ge "$MINOR_UNSTABLE" ] ) \
     || [ "$MAJOR_STABLE" -gt "$MAJOR_UNSTABLE" ]; then
    echo "Latest unstable version ('$VERSION') is not higher than the latest stable version ('$STABLE_VERSION')."
    exit 0
  fi
fi

./build.sh "${VERSION}" $@
