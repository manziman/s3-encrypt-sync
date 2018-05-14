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
    find $dir -type f -not -name "*.gpg" -exec gpg --batch --yes --output {}.gpg --recipient christophermmanzi@protonmail.com --encrypt {} \;
    aws s3 sync --include "*.gpg" $dir s3://$S3_BUCKET/$remote_dir
done

