#!/bin/bash

NEEDED_COMMANDS="curl jq docker skopeo"
for c in $NEEDED_COMMANDS; do
  if ! command -v "$c" &>/dev/null; then
    echo "⚠️  '$c' is not installed. Can't proceed with build."
    exit 1
  fi
done
