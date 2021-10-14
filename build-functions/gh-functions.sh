#!/bin/bash

###
# A regular echo, that only prints if ${GH_ACTION} is defined.
###
gh_echo() {
  if [ -n "${GH_ACTION}" ]; then
    echo "${@}"
  fi
}

###
# Prints the output to the file defined in ${GITHUB_ENV}.
# Only executes if ${GH_ACTION} is defined.
# Example Usage: gh_env "FOO_VAR=bar_value"
###
gh_env() {
  if [ -n "${GH_ACTION}" ]; then
    echo "${@}" >>"${GITHUB_ENV}"
  fi
}
