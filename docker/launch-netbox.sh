#!/bin/bash

export GRANIAN_PORT=${GRANIAN_PORT:-8080}
export GRANIAN_WORKERS=${GRANIAN_WORKERS:-4}

exec granian \
  --host "::" \
  --interface "wsgi" \
  --no-ws \
  --respawn-failed-workers \
  --loop "uvloop" \
  --log \
  --log-level "info" \
  --access-log \
  --working-dir "/opt/netbox/netbox/" \
  --static-path-route "/static" \
  --static-path-mount "/opt/netbox/netbox/static/" \
  --static-path-dir-to-file index.html \
  --pid-file "/tmp/granian.pid" \
  "${GRANIAN_EXTRA_ARGS[@]}" \
  "netbox.granian:application"
