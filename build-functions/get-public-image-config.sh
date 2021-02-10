#!/bin/bash
# Retrieves image configuration from public images in DockerHub
# Functions from https://gist.github.com/cirocosta/17ea17be7ac11594cb0f290b0a3ac0d1
# Optimised for our use case

get_image_label() {
  local label=$1
  local image=$2
  local tag=$3
  local token
  token=$(_get_token "$image")
  local digest
  digest=$(_get_digest "$image" "$tag" "$token")
  local retval="null"
  if [ "$digest" != "null" ]; then
    retval=$(_get_image_configuration "$image" "$token" "$digest" "$label")
  fi
  echo "$retval"
}

get_image_layers() {
  local image=$1
  local tag=$2
  local token
  token=$(_get_token "$image")
  _get_layers "$image" "$tag" "$token"
}

get_image_last_layer() {
  local image=$1
  local tag=$2
  local token
  token=$(_get_token "$image")
  local layers
  mapfile -t layers < <(_get_layers "$image" "$tag" "$token")
  echo "${layers[-1]}"
}

_get_image_configuration() {
  local image=$1
  local token=$2
  local digest=$3
  local label=$4
  curl \
    --silent \
    --location \
    --header "Authorization: Bearer $token" \
    "https://registry-1.docker.io/v2/$image/blobs/$digest" |
    jq -r ".config.Labels.\"$label\""
}

_get_token() {
  local image=$1
  curl \
    --silent \
    "https://auth.docker.io/token?scope=repository:$image:pull&service=registry.docker.io" |
    jq -r '.token'
}

_get_digest() {
  local image=$1
  local tag=$2
  local token=$3
  curl \
    --silent \
    --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    --header "Authorization: Bearer $token" \
    "https://registry-1.docker.io/v2/$image/manifests/$tag" |
    jq -r '.config.digest'
}

_get_layers() {
  local image=$1
  local tag=$2
  local token=$3
  curl \
    --silent \
    --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    --header "Authorization: Bearer $token" \
    "https://registry-1.docker.io/v2/$image/manifests/$tag" |
    jq -r '.layers[].digest'
}
