#!/bin/bash

# exit when a command exits with an exit code != 0
set -e

# version is used by `docker-compose.yml` do determine the tag
# of the Docker Image that is to be used
export VERSION=${VERSION-latest}

test_netbox_unit_tests() {
  echo "⏱ Running Netbox Unit Tests"
  docker-compose run --rm netbox ./manage.py test
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

  docker-compose run --rm netbox ./manage.py check
}

test_cleanup() {
  echo "💣 Cleaning Up"
  docker-compose down -v
  rm -rf initializers
  mv initializers_original initializers
}

echo "🐳🐳🐳 Start testing '${VERSION}'"

# Make sure the cleanup script is executed
trap test_cleanup EXIT ERR

test_netbox_unit_tests
test_initializers

echo "🐳🐳🐳 Done testing '${VERSION}'"
