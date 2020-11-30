Docker Container to monitor the functionality of a remote storage.

Uses [rclone](URL='https://rclone.org') to do all storage transactions. Currently only s3 storage and FTP are supported, but this can easily be expanded via the setup.sh script.

It uploads a generated file to the remote storage and downloads it afterwards. This repeats every 4 minutes. MD5SUMs are compared, filesizes and timings are measured.
All results are exposed in a prometheus exporter format, Port 9000 unter /

The Storage is configured via config files containing environment variables.
The credentials can be placed in seperate .env files, which can come from a different source, e.g. a kubernetes secret.
The ENV Variable names must contain underscores, no dashes. The "targets" in the filenames must not contain any dashes, as they are used for the rclone targetnames.
