#!/bin/bash

URL_LATEST=https://api.github.com/repos/digitalocean/netbox/releases/latest

VERSION=$(curl "${URL_LATEST}" | jq -r ".tag_name")

./build.sh "${VERSION}" --push
