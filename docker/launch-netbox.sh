#!/bin/bash

exec granian \
  --host "::" \
  --port "8080" \
  --interface "wsgi" \
  --no-ws \
  --workers "4" \
  --backpressure "4" \
  --loop "uvloop" \
  --log \
  --log-level "info" \
  --access-log \
  --working-dir "/opt/netbox/netbox/" \
  --static-path-route "/static" \
  --static-path-mount "/opt/netbox/netbox/static/" \
  --pid-file "/tmp/granian.pid" \
  "netbox.granian:application"
