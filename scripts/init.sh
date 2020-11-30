#!/bin/bash

. ./generic.inc

log "Starting lighthttpd"
lighttpd -f /app/lighttpd.conf
cd /app
echo "* * * * * /app/create_html.sh" > /app/crontab
supercronic -json /app/crontab &
log "Setting up Tests"
./setup.sh
sleep 600000
#./run_test.sh
exit $?
