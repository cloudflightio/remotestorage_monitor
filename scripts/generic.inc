RCLONE_CONFIGFILE="/app/rclone.conf"
# local testing
#RCLONE_CONFIGFILE="./rclone.conf"

JSONLOG=1
# local testing
#JSONLOG=0

log() {
  if (( $JSONLOG == 1 )); then
    TS=$(date +%s)
    # TODO: Only in a container
    printf '{"ts":"%i","level":"info","msg":"%s"}\n' "${TS}" "${*}" # > /proc/1/fd/1
   else
    TS=$(date +%H:%M:%S)
    echo ${TS}: ${*}
  fi
}

error() {
  if (( $JSONLOG == 1 )); then
    TS=$(date +%s)
    printf '{"ts":"%i","level":"err","msg":"%s"}\n' "${TS}" "${*}"
   else
    TS=$(date +%H:%M:%S)
    >&2 echo ${TS}: ${*}
  fi
}

clear_env() {
# generic
  unset TYPE UPLOAD DOWNLOAD TESTFILESIZE TESTFILENAME
# ftp
  unset HOST PORT USER PASS TLS
# s3
  unset PROVIDER ACCESS_KEY_ID SECRET_ACCESS_KEY ENDPOINT REGION
# set default values
  UPLOAD=0
  DOWNLOAD=0
  TESTFILESIZE=5M
  DO_CLEANUP=1
  TESTFILENAME="testfile"
  # TODO: default interval higher
  INTERVAL=1
}
