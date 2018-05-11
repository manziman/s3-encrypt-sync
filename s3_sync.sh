#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! [ -f ${SCRIPT_DIR}/s3_sync.config ]; then
    echo "No config file present! Exiting..."
    exit
fi

source ${SCRIPT_DIR}/s3_sync.config

# Sync all directories
IFS=","
for dir in $DIRECTORIES; do
    remote_dir=$(echo $dir | sed 's/.*\///g')
    mkdir /tmp/$remote_dir
    find $dir -type f -not -name "*.gpg" -exec cp --parents {} /tmp/$remote_dir/ \;
    find /tmp/$remote_dir/ -type f -not -name "*.gpg" -exec gpg --batch --yes --output {}.gpg --recipient christophermmanzi@protonmail.com --encrypt {} \;
    find /tmp/$remote_dir -type f -not -name "*.gpg" -exec shred -zvu {} > /dev/null \;
    aws s3 sync --include "*.gpg" /tmp/$remote_dir s3://$S3_BUCKET/$remote_dir
    find /tmp/$remote_dir/ -type f -name "*.gpg" -exec cp {} $dir \;
    rm -rf /tmp/$remote_dir
done

