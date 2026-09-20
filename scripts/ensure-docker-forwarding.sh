#!/bin/sh
set -eu

command -v iptables-legacy >/dev/null 2>&1 || {
    echo "iptables-legacy is required" >&2
    exit 1
}

if [ "$(id -u)" -ne 0 ]; then
    exec sudo -n iptables-legacy -P FORWARD ACCEPT
fi

iptables-legacy -P FORWARD ACCEPT