#!/bin/busybox sh
# This scirpt is using by udev service
# to start automatic update procedure

# define log file for update progress
UPDATE_STATE_FILE="/tmp/updatestate.log"
# update successful is value from fs_updater_error.h
# UPDATER_FIRMWARE_AND_APPLICATION_STATE
UPDATE_SUCCESSFUL='0 4 8'

# check for configuration file
if [ ! -f "$1/update_config" ]; then
    echo "$1/update_config does not exist." >> $UPDATE_STATE_FILE
else
    # check for string to set environment UPDATE_FILE
    if grep -q "export UPDATE_FILE=" $1/update_config; then
        # set environmets which are required by fs-updater
        # in automatic update mode.
        source $1/update_config
        export UPDATE_STICK="$1"
        update_type='nok'
        if grep -q "export UPDATE_TYPE=" $1/update_config; then
            if [ $UPDATE_TYPE = 'app' ]; then
                update_type='ok'
            elif [ $UPDATE_TYPE = 'fw' ]; then
                update_type='ok'
            fi
        fi
        echo "Update started..." >> $UPDATE_STATE_FILE
        echo "Update type $UPDATE_TYPE - $update_type" >> $UPDATE_STATE_FILE
        if [ $update_type = 'ok' ]; then
            fs-updater --automatic --update_type $UPDATE_TYPE
        else
            fs-updater --automatic
        fi
        return_state=$?
        for SUCCESS in $UPDATE_SUCCESSFUL; do
            if [ "$return_state" = "$SUCCESS" ]; then
                echo "Apply update..." >> $UPDATE_STATE_FILE
                fs-updater --apply_update
                return_state=0
                break
            fi
        done
        if [ "$return_state" != '0' ]; then
            echo "Update fails ret: $return_state" >> $UPDATE_STATE_FILE
        fi
    else
        echo "Environment UPDATE_FILE is not available." >> $UPDATE_STATE_FILE
        echo 'Add line e.g. export UPDATE_FILE="update.fs".' >> $UPDATE_STATE_FILE
    fi
fi
