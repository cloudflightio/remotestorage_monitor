#!/bin/bash -e

. ./generic.inc

setup_s3() {
  set -e
  rclone --config ${RCLONE_CONFIGFILE} config create ${TARGET} "${TYPE}" \
    env_auth false \
    provider "${PROVIDER}" \
    access_key_id "${ACCESS_KEY_ID}" \
    secret_access_key "${SECRET_ACCESS_KEY}" \
    endpoint "${ENDPOINT}" \
    region "${REGION}" &> /dev/null
  set +e
}

setup_ftp() {
  set -e
  rclone --config ${RCLONE_CONFIGFILE} config create ${TARGET} "${TYPE}" \
    host "${HOST}" \
    port "${PORT}" \
    user "${USER}" \
    pass "${PASS}" \
    tls "${TLS}" &> /dev/null
  set +e
}

setup_cronjob() {
#  log $(echo $(dirname $(realpath $0))/run_test.sh ${TARGET} | at now + ${INTERVAL} minutes 2>&1)
  echo "*/${INTERVAL} * * * * /app/run_test.sh ${TARGET}" >> /app/crontab
  killall -USR2 supercronic
}

# TODO: Check if config directory exists
cd config
TARGETS=$(ls -1 *.conf | rev | cut -b 6- | rev)
cd ..

# TODO: source secrets if available

## Setup Rclone Config
log "Setting up Remote Targets"
clear_env
for TARGET in ${TARGETS}; do
  log "New target: ${TARGET}"
  . ./env/${TARGET}.env
  . ./config/${TARGET}.conf
  case "${TYPE}" in
    "s3")
      setup_s3
      ;;
    "ftp")
      setup_ftp
      ;;
    *)
      error "Sorry, target TYPE ${TYPE} is not (yet) supported!"
      exit 1
  esac
  log "Setting up Cronjob"
  setup_cronjob
  clear_env
  log "Testing connection"
  OUTPUT=$(rclone --config ${RCLONE_CONFIGFILE} -vvv --timeout 10s --retries 1 --contimeout 10s --low-level-retries 1 lsd ${TARGET}: 2>&1)
  RETVAL=$?
  if (( $RETVAL != 0 )); then
    error "Connection to ${TARGET} not successful. Exitcode ${RETVAL}. Please check configuration. Aborting."
    exit 0
  else
    log "OK"
  fi
done

# TODO: Own cronjob for updating webpage

log "List of targets in config: "$(rclone --config ${RCLONE_CONFIGFILE} listremotes)

exit 0
