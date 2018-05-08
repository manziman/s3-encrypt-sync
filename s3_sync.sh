#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! [ -f ${SCRIPT_DIR}/s3_sync.config ]; then
    echo "No config file present! Exiting..."
    exit
fi

source ${SCRIPT_DIR}/s3_sync.config

# Sync all directories


