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

INITIALIZERS_DIR=".initializers"

test_setup() {
  echo "🏗 Setup up test environment"
  if [ -d "${INITIALIZERS_DIR}" ]; then
    rm -rf "${INITIALIZERS_DIR}"
  fi

  mkdir "${INITIALIZERS_DIR}"
  (
    cd initializers
    for script in *.yml; do
      sed -E 's/^# //' "${script}" > "../${INITIALIZERS_DIR}/${script}"
    done
  )
}

test_netbox_unit_tests() {
  echo "⏱ Running Netbox Unit Tests"
  $doco run --rm netbox ./manage.py test
}

test_initializers() {
  echo "🏭 Testing Initializers"
  export INITIALIZERS_DIR
  $doco run --rm netbox ./manage.py check
}

test_cleanup() {
  echo "💣 Cleaning Up"
  $doco down -v

  if [ -d "${INITIALIZERS_DIR}" ]; then
    rm -rf "${INITIALIZERS_DIR}"
  fi
}

echo "🐳🐳🐳 Start testing '${IMAGE}'"

# Make sure the cleanup script is executed
trap test_cleanup EXIT ERR
test_setup

test_netbox_unit_tests
test_initializers

echo "🐳🐳🐳 Done testing '${IMAGE}'"
