#!/bin/bash

check_if_tags_exists() {
  local image=$1
  local tag=$2
  skopeo list-tags "docker://$image" | jq -r ".Tags | contains([\"$tag\"])"
}

get_image_label() {
  local label=$1
  local image=$2
  skopeo inspect "docker://$image" | jq -r ".Labels[\"$label\"]"
}

get_image_last_layer() {
  local image=$1
  skopeo inspect "docker://$image" | jq -r ".Layers | last"
}
