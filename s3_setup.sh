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

# Select cron or systemd timer
while true; do
    read -p "Would you like to run sync on a schedule?(Y/n)" yn
    case $yn in
        [Nn]* ) break;;
        [Yy]* ) break;;
            * ) echo "Please input yes or no."; continue;;
    esac
done

PS3="Please select either systemd timers or cron: "
options=("systemd Timer" "cronjob" "cancel")
select opt in "${options[@]}"
do
    case $opt in
        "systemd Timer")
            echo "Using systemd Timer"
            selection="timer"
            break
            ;;
        "cronjob")
            echo "Using cronjob"
            selection="cron"
            break
            ;;
        "cancel")
            break
            ;;
        *) echo "invalid option";;
    esac
done

# Get input for cron or timer
if [ $seleciton == "cron" ]; then
    read -p "min: " min
    read -p "hour: " hour
    read -p "day: " day
    read -p "month: " month
    read -p "weekday: " weekday
elif [ $selection == "timer" ]; then
    PS3="Please select a frequency (or custom): "
    options=("minutely" "hourly" "daily" "monthly" "weekly" "custom" "cancel")
    select opt in "${options[@]}"
    do
        case $opt in
            "minutely")
                datestring="*-*-* *:*:00"
                break
                ;;
            "hourly")
                datestring="*-*-* *:00:00"
                break
                ;;
            "daily")
                datestring="*-*-* 00:00:00"
                break
                ;;
            "monthly")
                datestring="*-*-01 00:00:00"
                break
                ;;
            "weekly")
                datestring="Mon *-*-* 00:00:00"
                break
                ;;
            "custom")
                read -p "Please enter custom datestring (DOW YR-MO-DAY HR:MIN:SEC): " datestring
                break
                ;;
            *) echo "invalid option";;
        esac
    done
    sudo bash -c "echo -e \"[Unit]\r\nDescription=Run backup to S3 on ${DIRECTORIES}\r\n\r\n[Timer]\r\nOnCalendar=${datestring}\r\nUnit=s3_backup.service\r\n\r\n[Install]\r\nWantedBy=timers.target\" > /usr/lib/systemd/system/s3_backup.timer"
    sudo bash -c "echo -e \"[Unit]\r\nDescription=Run backup to S3 on ${DIRECTORIES}\r\n\r\n[Service]\r\nType=simple\r\nExecStart=${SCRIPT_DIR}/s3_sync.sh\r\nUser=${usr}\r\n\r\n[Install]\r\nWantedBy=timers.target\" > /usr/lib/systemd/system/s3_backup.service"

    sudo systemctl enable backup.timer
    
    while true; do
        read -p "Would you like to start now?(Y/n)" yn
        case $yn in
            [Nn]* ) break;;
            [Yy]* ) sudo systemctl start; break;;
                * ) echo "Please input yes or no."; continue;;
        esac
    done
fi

# Iterate through directories and sync
IFS=","
for d in $DIRECTORIES; do
    echo $d
done
