#!/bin/bash
# run preentry script to install any local depencencies / file mods
/opt/netbox/preentry.sh

SECONDS=${HOUSEKEEPING_INTERVAL:=86400}
echo "Interval set to ${SECONDS} seconds"
while true; do
  date
  /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py housekeeping
  sleep "${SECONDS}s"
done
