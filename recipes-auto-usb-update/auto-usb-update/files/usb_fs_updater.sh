#!/bin/busybox sh
source $1/update_config
export UPDATE_STICK="$1"
FS-Update --automatic
