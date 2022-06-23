#!/bin/bash

UNIT_SOCKET="/opt/unit/unit.sock"

put_config() {
  RET=$(
    curl \
    --silent \
    --write-out '%{http_code}' \
    --request PUT \
    --data-binary "@$1" \
    --unix-socket $UNIT_SOCKET \
    http://localhost/$2
  )
  RET_BODY=${RET::-3}
  RET_STATUS=$(echo $RET | tail -c 4)

  echo $RET

  if [ "$RET_STATUS" -ne "200" ]; then
      echo "⚠️ Error: Failed to load configuration from $1"
      ( echo "HTTP response status code is '$RET_STATUS'"
        echo "$RET_BODY"
      ) | sed 's/^/  /'

      kill "$(cat /opt/unit/unit.pid)"
      return 1
  fi

  return 0
}

load_configuration() {
  MAX_WAIT=10
  WAIT_COUNT=0
  while [ ! -S $UNIT_SOCKET ]; do
    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
      echo "⚠️ No control socket found; configuration will not be loaded."
      return 1
    fi

    WAIT_COUNT=$((WAIT_COUNT + 1))
    echo "⏳ Waiting for control socket to be created... (${WAIT_COUNT}/${MAX_WAIT})"

    sleep 1
  done

  # even when the control socket exists, it does not mean unit has finished initialisation
  # this curl call will get a reply once unit is fully launched
  curl --silent --output /dev/null --request GET --unix-socket $UNIT_SOCKET http://localhost/

  if [[ -n "$UNIT_CONFIG" ]] && [[ -s "$UNIT_CONFIG" ]]; then
    echo "⚠️ The UNIT_CONFIG environment variable is deprecated. All *.pem and *.json files in /etc/unit will be loaded automatically when UNIT_CONFIG is undefined."
    echo "⚙️ Applying configuration from UNIT_CONFIG environment variable: $UNIT_CONFIG"
    put_config $UNIT_CONFIG "config" || return 1
  else
    echo "🔍 Looking for certificate bundles in /etc/unit/..."
    for f in $(find /etc/unit/ -type f -name "*.pem"); do
      echo "⚙️ Uploading certificates bundle: $f"
      put_config $f "certificates/$(basename $f .pem)" || return 1
    done

    echo "🔍 Looking for configuration snippets in /etc/unit/..."
    for f in $(find /etc/unit/ -type f -name "*.json"); do
      echo "⚙️ Applying configuration $f";
      put_config $f "config" || return 1
    done

    # warn on filetypes we don't know what to do with
    for f in $(find /etc/unit/ -type f -not -name "*.json" -not -name "*.pem"); do
      echo "↩️ Ignoring $f";
    done
  fi

  echo "✅ Unit configuration loaded successfully"
}

if [ -n "$(ls -A /opt/unit/state)" ]; then
  echo "💣 Clearing previous unit state from /opt/unit/state"
  rm -r /opt/unit/state/*
fi

load_configuration &

exec unitd \
  --no-daemon \
  --control unix:$UNIT_SOCKET \
  --pid /opt/unit/unit.pid \
  --log /dev/stdout \
  --state /opt/unit/state/ \
  --tmp /opt/unit/tmp/ \
  --user unit \
  --group root
