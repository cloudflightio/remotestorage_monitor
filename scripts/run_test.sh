#!/bin/bash

TARGET=$1

. ./generic.inc

clear_env

. ./config/${TARGET}.conf

touch /tmp/run.${TARGET}

TESTFILENAME="/tmp/testfile.${TARGET}"

create_testfile() {
  dd if=/dev/zero of=${TESTFILENAME} bs="${TESTFILESIZE}" count=1 status=none > /dev/null
}

run_check() {
  UPLOADSIZE=$(stat -c "%s" ${TESTFILENAME})
  LOCALMD5=$(md5sum ${TESTFILENAME} | awk '{ print $1 }')
  /usr/bin/time -f "%e" -o /tmp/${TARGET}.upload.duration   rclone --config /app/rclone.conf --max-duration 2m --timeout 25s --retries 1 copy ${TESTFILENAME} ${TARGET}:/${BUCKET}/
  echo $? > /tmp/${TARGET}.upload.code
  /usr/bin/time -f "%e" -o /tmp/${TARGET}.download.duration rclone --config /app/rclone.conf --max-duration 2m --timeout 25s --retries 1 copyto ${TARGET}:/${BUCKET}/testfile.${TARGET} ${TESTFILENAME}2
  echo $? > /tmp/${TARGET}.download.code
  LOCALMD52=$(md5sum ${TESTFILENAME}2 | awk '{ print $1 }')
  DOWNLOADSIZE=$(stat -c "%s" ${TESTFILENAME}2)
  rm -f ${TESTFILENAME}2
  /usr/bin/time -f "%e" -o /tmp/${TARGET}.cleanup.duration  rclone --config /app/rclone.conf -q deletefile ${TARGET}:/${BUCKET}/testfile.${TARGET} 2> /dev/null
  echo $? > /tmp/${TARGET}.cleanup.code

  if [ "abc${LOCALMD5}" == "abc${LOCALMD52}" ]; then
    MD5OK="1"
   else
    MD5OK="0"
  fi
  echo ${UPLOADSIZE} > /tmp/${TARGET}.uploadsize
  echo ${DOWNLOADSIZE} > /tmp/${TARGET}.downloadsize
  echo ${MD5OK} > /tmp/${TARGET}.md5ok
  date +%s > /tmp/${TARGET}.timestamp
  mkdir -p "/tmp/finished/"
  cp /tmp/${TARGET}.* /tmp/finished/
}

if [ ! -f "${TESTFILENAME}.${TARGET}" ]; then
  create_testfile
fi
run_check
