#!/bin/bash
# TODO: Keep track of file changes and update gpg files when needed

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
    find $dir -type f -not -name "*.gpg" -exec gpg --batch --output {}.gpg --recipient christophermmanzi@protonmail.com --encrypt {}  2>/dev/null \;
    aws s3 sync --exclude "*" --include "*.gpg" $dir s3://$S3_BUCKET/$remote_dir --profile $AWS_PROFILE
done

