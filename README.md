Docker Container to monitor the functionality of a remote storage.

Uses [rclone](URL='https://rclone.org') to do all storage transactions. Currently only s3 storage is supported.

It uploads a generated file to the remote storage and downloads it afterwards. This repeats every 4 minutes. MD5SUMs are compared, filesizes and timings are measured.
All results are exposed in a prometheus exporter format, Port 9000 unter /

The Storage is configured via ENV Vars:
```
# defaults: 
TESTFILESIZE="3M"
TYPE="s3"
PROVIDER="Minio"
# needed
ACCESS_KEY_ID="setme"
SECRET_ACCESS_KEY="setme"
ENDPOINT="setme"
REGION="setme"
BUCKET="setme"
```

