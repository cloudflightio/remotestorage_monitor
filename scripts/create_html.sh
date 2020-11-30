#!/bin/bash

. ./generic.inc

cd config
TARGETS=$(ls -1 *.conf | rev | cut -b 6- | rev)
cd ..
HAVEDATA=0

create_target_html() {
  if [ ! -f /tmp/finished/${TARGET}.upload.duration ]; then
    log "No results for ${TARGET} yet, skipping."
    return
  fi
  HAVEDATA=1
  UPLOAD=$(cat /tmp/finished/${TARGET}.upload.duration)
  DOWNLOAD=$(cat /tmp/finished/${TARGET}.download.duration)
  CLEANUP=$(cat /tmp/finished/${TARGET}.cleanup.duration)
  UPLOADCODE=$(cat /tmp/finished/${TARGET}.upload.code)
  DOWNLOADCODE=$(cat /tmp/finished/${TARGET}.download.code)
  CLEANUPCODE=$(cat /tmp/finished/${TARGET}.cleanup.code)
  MD5OK=$(cat /tmp/finished/${TARGET}.md5ok)
  TIMESTAMP=$(cat /tmp/finished/${TARGET}.timestamp)
  UPLOADSIZE=$(cat /tmp/finished/${TARGET}.uploadsize)
  DOWNLOADSIZE=$(cat /tmp/finished/${TARGET}.downloadsize)
  UPANDDOWNLOAD=$(echo "${UPLOAD} + ${DOWNLOAD}" | bc)

  echo "remotestorage_upload_seconds{target=\"${TARGET}\",} ${UPLOAD}
remotestorage_upload_size{target=\"${TARGET}\",} ${UPLOADSIZE}
remotestorage_upload_exitcode{target=\"${TARGET}\",} ${UPLOADCODE}" > /app/htdocs/snippets/${TARGET}.upload

  echo "remotestorage_download_seconds{target=\"${TARGET}\",} ${DOWNLOAD}
remotestorage_download_size{target=\"${TARGET}\",} ${DOWNLOADSIZE}
remotestorage_download_exitcode{target=\"${TARGET}\",} ${DOWNLOADCODE}" > /app/htdocs/snippets/${TARGET}.download

  echo "remotestorage_transfer_sum{target=\"${TARGET}\",} ${UPANDDOWNLOAD}" > /app/htdocs/snippets/${TARGET}.transfer

  echo "remotestorage_md5ok{target=\"${TARGET}\",} ${MD5OK}" > /app/htdocs/snippets/${TARGET}.md5

  echo "remotestorage_cleanup_seconds{target=\"${TARGET}\",} ${CLEANUP}
remotestorage_cleanup_exitcode{target=\"${TARGET}\",} ${CLEANUPCODE}" > /app/htdocs/snippets/${TARGET}.cleanup

  echo "remotestorage_timestamp{target=\"${TARGET}\",} ${TIMESTAMP}" > /app/htdocs/snippets/${TARGET}.timestamp
}

create_html() {
  if [ $HAVEDATA == 0 ]; then
    return
  fi
  TMPFILE=$(mktemp)

  echo "# HELP remotestorage_upload_seconds Duration of the file upload in seconds
# TYPE remotestorage_upload_seconds gauge" > $TMPFILE
  cat /app/htdocs/snippets/*.upload >> $TMPFILE
  echo "# HELP remotestorage_download_seconds Duration of the file download in seconds
# TYPE remotestorage_download_seconds gauge" >> $TMPFILE
  cat /app/htdocs/snippets/*.download >> $TMPFILE
  echo "# HELP remotestorage_transfer_sum Summary of up and download in seconds
# TYPE remotestorage_transfer_sum gauge" >> $TMPFILE
  cat /app/htdocs/snippets/*.transfer >> $TMPFILE
  echo "# HELP remotestorage_md5ok Is the downloaded file content the same as the uploaded one?
# TYPE remotestorage_md5ok gauge" >> $TMPFILE
  cat /app/htdocs/snippets/*.md5 >> $TMPFILE
  cat /app/htdocs/snippets/*.cleanup >> $TMPFILE
  echo "# HELP remotestorage_timestamp Timestamp of last check
# TYPE remotestorage_timestamp counter" >> $TMPFILE
  cat /app/htdocs/snippets/*.timestamp >> $TMPFILE
  mv $TMPFILE /app/htdocs/index.html
}

mkdir -p /app/htdocs/snippets

for TARGET in ${TARGETS}; do
  clear_env
  create_target_html
done
create_html
