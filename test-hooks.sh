#!/bin/bash
# This helps testing and debugging the build hooks

# exit when a command exits with an exit code != 0
set -e

prepare() {
  echo "⏱ Preparing"
}

cleanup() {
  echo "💣 Cleaning Up"

}

run_test() {
  branch="${1}"
  tag="${2}"
  echo "🏗 Testing Hook for SOURCE_BRANCH=\"${branch}\" and DOCKER_TAG=\"${tag}\""

  export SOURCE_BRANCH="${branch}"
  SOURCE_COMMIT="$(git rev-parse HEAD)"
  export SOURCE_COMMIT
  export COMMIT_MSG=test
  export DOCKER_REPO=netboxcommunity/netbox
  export DOCKERFILE_PATH=Dockerfile
  export DOCKER_TAG="${tag}"
  export IMAGE_NAME="${DOCKER_REPO}:${DOCKER_TAG}"

  echo "SOURCE_COMMIT=${SOURCE_COMMIT}"

  hooks/build
  hooks/test
  DRY_RUN=on hooks/push
}

echo "🐳🐳🐳 Start testing"

# Make sure the cleanup script is executed
trap cleanup EXIT ERR

prepare
run_test release branches
run_test release prerelease
run_test release release

echo "🐳🐳🐳 Done testing"
