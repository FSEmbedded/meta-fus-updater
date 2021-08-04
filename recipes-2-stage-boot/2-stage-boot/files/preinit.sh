#!/bin/busybox sh

# Run the dynamic_overlay
/sbin/dynamic_overlay


# Boot the real thing.
exec /sbin/init
