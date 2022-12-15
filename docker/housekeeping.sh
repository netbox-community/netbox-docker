#!/bin/bash
SLEEP_SECONDS=${HOUSEKEEPING_INTERVAL:=86400}
echo "Interval set to ${SLEEP_SECONDS} seconds"
while true; do
  date
  /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py housekeeping
  sleep "${SLEEP_SECONDS}s"
done
