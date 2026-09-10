#!/bin/bash

export CHECK_PORT=${GRANIAN_PORT:-8080}
curl -sf "http://localhost:${CHECK_PORT}/login/" >/dev/null || exit 1
