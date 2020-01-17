#!/bin/bash

# exit when a command exits with an exit code != 0
set -e

# version is used by `docker-compose.yml` do determine the tag
# of the Docker Image that is to be used
export IMAGE="${IMAGE-netboxcommunity/netbox:latest}"

if [ -z "${IMAGE}" ]; then
  echo "⚠️ No image defined"

  if [ -z "${DEBUG}" ]; then
    exit 1;
  else
    echo "⚠️ Would 'exit 1' here, but DEBUG is '${DEBUG}'."
  fi
fi

# The docker compose command to use
doco="docker-compose -f docker-compose.test.yml"

test_netbox_unit_tests() {
  echo "⏱ Running Netbox Unit Tests"
  $doco run --rm netbox ./manage.py test
}

test_initializers() {
  echo "🏗 Testing Initializers"

  mkdir initializers_test
  (
    cd initializers
    for script in *.yml; do
      sed -E 's/^# //' "${script}" > "../initializers_test/${script}"
    done
  )
  mv initializers initializers_original
  mv initializers_test initializers

  $doco run --rm netbox ./manage.py check
}

test_cleanup() {
  echo "💣 Cleaning Up"
  $doco down -v

  if [ -d initializers_original ]; then
    rm -rf initializers
    mv initializers_original initializers
  fi
}

echo "🐳🐳🐳 Start testing '${IMAGE}'"

# Make sure the cleanup script is executed
trap test_cleanup EXIT ERR

test_netbox_unit_tests
test_initializers

echo "🐳🐳🐳 Done testing '${IMAGE}'"
