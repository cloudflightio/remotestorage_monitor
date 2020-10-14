#!/bin/bash

log() {
  TS=$(date +%s)
  printf '{"ts":"%i","level":"info","msg":"%s"}\n' "${TS}" "${*}"
}

log "Starting lighthttpd..."
lighttpd -f /app/lighttpd.conf
log "Starting tests..."
cd  /app
./run_test.sh
exit $?
