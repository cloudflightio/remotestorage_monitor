#!/bin/bash -e

if [ -f "./env" ]; then
. ./env
fi

: "${TESTFILESIZE:=3M}"
: "${TYPE:=s3}"
: "${PROVIDER:=Minio}"
: "${ACCESS_KEY_ID:=unset}"
: "${SECRET_ACCESS_KEY:=unset}"
: "${ENDPOINT:=unset}"
: "${REGION:=unset}"
: "${BUCKET:=unset}"

log() {
  TS=$(date +%s)
  printf '{"ts":"%i","level":"info","msg":"%s"}\n' "${TS}" "${*}"
}

setup() {
  set -e
  log "Configuring rclone"
  rclone --config /app/rclone.conf config create testtarget "${TYPE}" \
    env_auth false \
    provider "${PROVIDER}" \
    access_key_id "${ACCESS_KEY_ID}" \
    secret_access_key "${SECRET_ACCESS_KEY}" \
    endpoint "${ENDPOINT}" \
    region "${REGION}" &> /dev/null
  # check rclone connection, will exit on error due to `set -e`
  log "Testing connection"
  OUTPUT=$(rclone --config /app/rclone.conf -vvv --timeout 10s --retries 1 --contimeout 10s --low-level-retries 1 lsl testtarget: 2>&1)
  RETVAL=$?
  log "${OUTPUT}"
  log $RETVAL
  log "Creating testfile"
  dd if=/dev/zero of=/tmp/testfile bs="${TESTFILESIZE}" count=1 status=none > /dev/null
  LOCALMD5=$(md5sum /tmp/testfile | awk '{ print $1 }')
  rm -f /tmp/testfile2
  set +e
  log "Removing old testfiles on remote storage."
  rclone --config /app/rclone.conf -q deletefile testtarget:/${BUCKET}/testfile 2> /dev/null
}

run_check() {
  UPLOADSIZE=$(stat -c "%s" /tmp/testfile)
  /usr/bin/time -f "%e" -o /tmp/upload   rclone --config /app/rclone.conf --max-duration 2m --timeout 25s --retries 1 copy /tmp/testfile testtarget:/${BUCKET}/
  echo $? > /tmp/upload.code
  /usr/bin/time -f "%e" -o /tmp/download rclone --config /app/rclone.conf --max-duration 2m --timeout 25s --retries 1 copyto testtarget:/${BUCKET}/testfile /tmp/testfile2
  echo $? > /tmp/download.code
  LOCALMD52=$(md5sum /tmp/testfile2 | awk '{ print $1 }')
  DOWNLOADSIZE=$(stat -c "%s" /tmp/testfile2)
  rm -f /tmp/testfile2
  /usr/bin/time -f "%e" -o /tmp/cleanup  rclone --config /app/rclone.conf -q deletefile testtarget:/${BUCKET}/testfile 2> /dev/null
  echo $? > /tmp/cleanup.code

  if [ "abc${LOCALMD5}" == "abc${LOCALMD52}" ]; then
    MD5OK="1"
   else
    MD5OK="0"
  fi

  TIMESTAMP=$(date +%s)
  UPLOAD=$(cat /tmp/upload)
  DOWNLOAD=$(cat /tmp/download)
  CLEANUP=$(cat /tmp/cleanup)
  UPLOADCODE=$(cat /tmp/upload.code)
  DOWNLOADCODE=$(cat /tmp/download.code)
  CLEANUPCODE=$(cat /tmp/cleanup.code)
  UPANDDOWNLOAD=$(echo "${UPLOAD} + ${DOWNLOAD}" | bc)

  echo "# HELP remotestorage_upload_seconds Duration of the file upload in seconds
# TYPE remotestorage_upload_seconds gauge
remotestorage_upload_seconds ${UPLOAD}
remotestorage_upload_size ${UPLOADSIZE}
remotestorage_upload_exitcode ${UPLOADCODE}
# HELP remotestorage_download_seconds Duration of the file download in seconds
# TYPE remotestorage_download_seconds gauge
remotestorage_download_seconds ${DOWNLOAD}
remotestorage_download_size ${DOWNLOADSIZE}
remotestorage_download_exitcode ${DOWNLOADCODE}
# HELP remotestorage_transfer_sum Summary of up and download in seconds
# TYPE remotestorage_transfer_sum gauge
remotestorage_transfer_sum ${UPANDDOWNLOAD}
# HELP remotestorage_md5ok Is the downloaded file content the same as the uploaded one?
# TYPE remotestorage_md5ok gauge
remotestorage_md5ok ${MD5OK}
remotestorage_cleanup_seconds ${CLEANUP}
remotestorage_cleanup_exitcode ${CLEANUPCODE}
# HELP remotestorage_timestamp Timestamp of last check
# TYPE remotestorage_timestamp counter
remotestorage_timestamp ${TIMESTAMP}

" > /app/htdocs/index.html
}

setup

log "Starting tests:"
while :
do
  log "Testing"
  run_check
  sleep 4m
done
