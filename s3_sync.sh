#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -f ${SCRIPT_DIR}/s3_sync.config  ]; then
    while true; do
        read -p "Config not found, set up now?(y/n)" yn
        case $yn in
            [Nn]* ) echo "Cannot continue without config!"; exit;;
            [Yy]* ) break;;
            * ) echo "Please input yes or no.";;
        esac
    done
    while true; do
        read -p "Please input username: " usr
        id -u ${usr}
        if [ ! $? == 0 ]; then
            echo "User ${usr} not found! Please enter valid user."; continue;
        else
           break
       fi 
    done
    while true; do
        read -p "Please enter GPG ID (email) of user: " email
        if ! [[ ${email} =~ ^[a-zA-Z0-9.\!\#\$%\&\'*+-=\/?^_\`{|}~]+@[a-zA-Z0-9]+\.[a-z]+$  ]]; then
            echo "Please enter a valid email."; continue;
        else
            break
        fi
    done
    DIRS=""
    while true; do
        read -p "Enter a directory to backup (<Enter> when done): " newdir
        if [ ! $newdir == "" ]; then
            if [ ! -d $newdir ]; then
                echo "Directory ${newdir} not found!"; continue;
            fi
            DIRS=${DIRS}$newdir,
        elif [ ${#DIRS[@]} -eq 0  ]; then
            echo "Please enter at least one directory!"; continue;
        else
            break
        fi
    done
    
    echo "# [user]" >> ${SCRIPT_DIR}/s3_sync.config
    echo "USERNAME=\"${usr}\"" >> ${SCRIPT_DIR}/s3_sync.config
    echo "GPG_KEY_ID=\"${email}\"" >> ${SCRIPT_DIR}/s3_sync.config
    echo "# [directories]" >> ${SCRIPT_DIR}/s3_sync.config
    echo "DIRECTORIES=\"${DIRS[@]}\"" >> ${SCRIPT_DIR}/s3_sync.config
fi

echo "Reading config file ${SCRIPT_DIR}/s3_sync.config..."
source ${SCRIPT_DIR}/s3_sync.config

cat ${SCRIPT_DIR}/s3_sync.config

IFS=","
for i in $DIRECTORIES; do
    echo $i
done
