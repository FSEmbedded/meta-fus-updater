#!/bin/busybox sh
source $1/update_config
export UPDATE_STICK="$1"
fs-updater --automatic
return_state=$?
if [[ "$return_state" -eq "0" ]]; then
    reboot
else
    echo "Update failed"
fi

