#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Construct necessary configs
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
        id -u ${usr} >> /dev/null
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

    while true; do
        read -p "Configure AWS profile/credentials now?(Y/n)" yn
        case $yn in
            [Nn]* ) read -p "Please enter existing AWS profile name: " profile;;
            [Yy]* ) read -p "Please enter the name for the new AWS profile: " newprofile;;
            * ) echo "Please input yes or no."; continue;;
        esac
        if [ $profile  ]; then
            grep "\[profile ${profile}\]" /home/${usr}/.aws/config
            if ! [ $? == 0 ]; then
                echo "Profile ${profile} not found!"; continue;
            fi
        else
            aws configure --profile $newprofile
            if ! [ $? == 0  ]; then
                continue
            else
                profile=$newprofile
                break
            fi
        fi
    done

    # S3 bucket name
    while true; do
        read -p "Please enter name of s3 bucket to use: " s3_bucket
        if ! [ s3_bucket ]; then
            echo "Please enter a bucket name."; continue;
        else
            aws s3 ls s3://${s3_bucket} --profile ${profile} >> /dev/null
            if ! [ $? == 0 ]; then
                echo "Unable to find/access bucket ${s3_bucket}"
                continue
            fi
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
    echo "# [aws]" >> ${SCRIPT_DIR}/s3_sync.config
    echo "AWS_PROFILE=\"${profile}\"" >> ${SCRIPT_DIR}/s3_sync.config
    echo "S3_BUCKET=\"${s3_bucket}\"" >> ${SCRIPT_DIR}/s3_sync.config
fi

# Read the config file and source it
echo "Reading config file ${SCRIPT_DIR}/s3_sync.config..."
source ${SCRIPT_DIR}/s3_sync.config

# Create cronjob if needed
while true; do
    read -p "Would you like to create a cronjob for the sync?(Y/n)" yn
    case $yn in
        [Nn]* ) break;;
        [Yy]* ) echo "Please provide cron timing information:";;
            * ) echo "Please input yes or no."; continue;;
    esac
    read -p "min: " min
    read -p "hour: " hour
    read -p "day: " day
    read -p "month: " month
    read -p "weekday: " weekday
done

# Iterate through directories and sync
IFS=","
for d in $DIRECTORIES; do
    echo $d
done
