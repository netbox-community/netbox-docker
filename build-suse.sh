#!/bin/sh -efux

SRC_ORG="${SRC_ORG-netbox-community}"
SRC_REPO="${SRC_REPO-netbox}"
URL="${URL-https://github.com/${SRC_ORG}/${SRC_REPO}.git}"

NETBOX_BRANCH="${1}"
NETBOX_PATH="${NETBOX_PATH-../netbox-git}"

git clone -q --depth 10 -b "${NETBOX_BRANCH}" "${URL}" "${NETBOX_PATH}"
git -C "${NETBOX_PATH}/.git" fetch -qp --depth 10 origin "${NETBOX_BRANCH}"
cd "${NETBOX_PATH}"
git checkout -qf FETCH_HEAD
cd "$OLDPWD"
git -C "${NETBOX_PATH}/.git" prune

GIT_REF="$(git rev-parse HEAD)"
PROJECT_VERSION="${PROJECT_VERSION-$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' VERSION)}"
NETBOX_GIT_REF="$(git -C "${NETBOX_PATH}/.git" rev-parse HEAD)"
NETBOX_GIT_BRANCH="$(git -C "${NETBOX_PATH}/.git" rev-parse --abbrev-ref HEAD)"
NETBOX_GIT_URL="$(git -C "${NETBOX_PATH}/.git" remote get-url origin)"

TAG="${NETBOX_BRANCH}-suse"

mv "$NETBOX_PATH" .netbox
NETBOX_PATH='.netbox'

NETBOX_PATH="$NETBOX_PATH" TAG="$TAG" docker-compose build

rm -r "$NETBOX_PATH"
