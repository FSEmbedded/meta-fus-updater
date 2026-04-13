#!/bin/sh

NO_UPDATE_REBOOT_PENDING=27

fs-updater --update_reboot_state
state=$?

if [ "$state" -eq "$NO_UPDATE_REBOOT_PENDING" ]; then
    echo "To mark-good service"
    exit 0
else
    echo "Skip mark-good service"
    exit 1
fi
