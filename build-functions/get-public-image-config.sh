#!/bin/bash

get_image_label() {
  local label=$1
  local image=$2
  skopeo inspect "docker://$image" | jq -r ".Labels[\"$label\"]"
}

get_image_last_layer() {
  local image=$1
  skopeo inspect "docker://$image" | jq -r ".Layers | last"
}
