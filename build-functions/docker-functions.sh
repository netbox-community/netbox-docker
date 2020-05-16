#!/bin/bash

push_image_to_registry() {
  local target_tag=$1
  echo "⏫ Pushing '${target_tag}'"
  $DRY docker push "${target_tag}"
  echo "✅ Finished pushing the Docker image '${target_tag}'."
}