#!/bin/bash

exec granian \
  --host "::" \
  --port "8080" \
  --interface "wsgi" \
  --no-ws \
  --workers "${GRANIAN_WORKERS:-4}" \
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
