#!/bin/bash

URL_LATEST=https://api.github.com/repos/digitalocean/netbox/releases

JQ_LATEST="group_by(.prerelease) | .[] | sort_by(.published_at) | reverse | .[0] | select(.prerelease==${PRERELEASE-false}) | .tag_name"

VERSION=$(curl "${URL_LATEST}" | jq -r "${JQ_LATEST}")

./build.sh "${VERSION}" $@

