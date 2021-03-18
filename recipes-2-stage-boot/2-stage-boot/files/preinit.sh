#!/bin/busybox sh

# Mount the /proc and /sys and /tmpfs filesystems.
mount -t proc none /proc
mount -t sysfs none /sys
mount -t ramfs ramfs /var
mkdir /var/lock

# Do your stuff here.
echo "This script mounts the overlay related to application in the persistent memory"

# Mount the root and persistent filesystem.
mount -t ext4 -o defaults /dev/mmcblk2p9 /rw_fs/root
mount -t ubifs -o defaults /dev/ubi0_2 /rw_fs/root
/usr/bin/python3 /rw_fs/dynamic_mounting.py

# Clean up.
umount /var
umount /proc
umount /sys


# Boot the real thing.
exec /sbin/init
