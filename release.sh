#!/bin/bash

DEFAULT_REPO=netbox-community/netbox-docker
REPO="${REPO-${DEFAULT_REPO}}"

echomoji() {
  EMOJI=${1}
  TEXT=${2}
  shift 2
  if [ -z "$DISABLE_EMOJI" ]; then
    echo "${EMOJI}" "${@}"
  else
    echo "${TEXT}" "${@}"
  fi
}

echo_nok() {
  echomoji "❌" "!" "${@}"
}
echo_ok() {
  echomoji "✅" "-" "${@}"
}
echo_hint() {
  echomoji "👉" ">" "${@}"
}

# check errors shall exit with code 1

check_clean_repo() {
  changes=$(git status --porcelain 2>/dev/null)
  if [ ${?} ] && [ -n "$changes" ]; then
    echo_nok "There are git changes pending:"
    echo "$changes"
    echo_hint "Please clean the repository before continueing: git stash --include-untracked"
    exit 1
  fi
  echo_ok "Repository has no pending changes."
}

check_branch() {
  expected_branch="${1}"
  actual_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ ${?} ] && [ "${actual_branch}" != "${expected_branch}" ]; then
    echo_nok "Current branch should be '${expected_branch}', but is '${actual_branch}'."
    echo_hint "Please change to the '${expected_branch}' branch: git checkout ${expected_branch}"
    exit 1
  fi
  echo_ok "The current branch is '${actual_branch}'."
}

check_upstream() {
  expected_upstream_branch="origin/${1}"
  actual_upstream_branch=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
  if [ ${?} ] && [ "${actual_upstream_branch}" != "${expected_upstream_branch}" ]; then
    echo_nok "Current upstream branch should be '${expected_upstream_branch}', but is '${actual_upstream_branch}'."
    echo_hint "Please set '${expected_upstream_branch}' as the upstream branch: git branch --set-upstream-to=${expected_upstream_branch}"
    exit 1
  fi
  echo_ok "The current upstream branch is '${actual_upstream_branch}'."
}

check_origin() {
  expected_origin="git@github.com:${REPO}.git"
  actual_origin=$(git remote get-url origin 2>/dev/null)
  if [ ${?} ] && [ "${actual_origin}" != "${expected_origin}" ]; then
    echo_nok "The url of origin is '${actual_origin}', but '${expected_origin}' is expected."
    echo_hint "Please set '${expected_origin}' as the url for origin: git origin set-url '${expected_origin}'"
    exit 1
  fi
  echo_ok "The current origin url is '${actual_origin}'."
}

check_latest() {
  git fetch --tags origin

  local_head_commit=$(git rev-parse HEAD 2>/dev/null)
  remote_head_commit=$(git rev-parse FETCH_HEAD 2>/dev/null)
  if [ "${local_head_commit}" != "${remote_head_commit}" ]; then
    echo_nok "HEAD is at '${local_head_commit}', but FETCH_HEAD is at '${remote_head_commit}'."
    echo_hint "Please ensure that you have pushed and pulled all the latest chanegs: git pull --prune --rebase origin; git push origin"
    exit 1
  fi
  echo_ok "HEAD and FETCH_HEAD both point to '${local_head_commit}'."
}

check_tag() {
  local tag

  tag=$(<VERSION)
  if git rev-parse "${tag}" 2>/dev/null >/dev/null; then
    echo_nok "The tag '${tag}' already points to '$(git rev-parse "${tag}" 2>/dev/null)'."
    echo_hint "Please ensure that the 'VERSION' file has been updated before trying to release: echo X.Y.Z > VERSION"
    exit 1
  fi
  echo_ok "The tag '${tag}' does not exist yet."
}

check_develop() {
  echomoji 📋 "?" "Checking 'develop' branch"

  check_branch develop
  check_upstream develop
  check_clean_repo
  check_latest
}

check_release() {
  echomoji 📋 "?" "Checking 'release' branch"

  check_upstream release
  check_clean_repo
  check_latest
}

# git errors shall exit with code 2

git_switch() {
  echomoji 🔀 "≈" "Switching to '${1}' branch…"
  if ! git checkout "${1}" >/dev/null; then
    echo_nok "It was not possible to switch to the branch '${1}'."
    exit 2
  fi
  echo_ok "The branch is now '${1}'."
}

git_tag() {
  echomoji 🏷 "X" "Tagging version '${1}'…"
  if ! git tag "${1}"; then
    echo_nok "The tag '${1}' was not created because of an error."
    exit 2
  fi
  echo_ok "The tag '$(<VERSION)' was created."
}

git_push() {
  echomoji ⏩ "»" "Pushing the tag '${2}' to '${1}'…"
  if ! git push "${1}" "${2}"; then
    echo_nok "The tag '${2}' could not be pushed to '${1}'."
    exit 2
  fi
  echo_ok "The tag '${2}' was pushed."
}

git_merge() {
  echomoji ⏩ "»" "Merging '${1}'…"
  if ! git merge --no-ff "${1}"; then
    echo_nok "The branch '${1}' could not be merged."
    exit 2
  fi
  echo_ok "The branch '${2}' was merged."
}

git_merge() {
  echomoji ⏩ "»" "Rebasing onto '${1}'…"
  if ! git rebase "${1}"; then
    echo_nok "Could not rebase onto '${1}'."
    exit 2
  fi
  echo_ok "Rebased onto '${2}'."
}

###
# MAIN
###

echomoji 📋 "▶︎" "Checking pre-requisites for releasing '$(<VERSION)'"

check_origin

check_develop
check_tag

git_switch release
check_release

echomoji 📋 "▶︎" "Releasing '$(<VERSION)'"

git_merge develop
check_tag
git_tag "$(<VERSION)"

git_push "origin" release
git_push "origin" "$(<VERSION)"

git_switch develop
git_rebase release

echomoji ✅ "◼︎" "The release of '$(<VERSION)' is complete."
