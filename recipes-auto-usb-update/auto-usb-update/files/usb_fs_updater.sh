#!/bin/sh
# Automatic USB/SD update for F&S Update Framework.
# Triggered by udev via fus-usb-update@.service; arg: device name (e.g. sda1).
set -eu

FS_UPDATER_BIN="/usr/sbin/fs-updater"
MOUNT_BASE="/tmp/fus_update"
UPDATE_STATE_FILE="/var/log/fus-updater.log"
LOCK_FILE="/run/lock/fus-updater.lock"
MOUNT_OPTS="ro,relatime,nodev,nosuid,noexec"
TMP_DIR="/tmp"
TMP_PKG=""
# Success codes from fs_updater_error.h
UPDATE_SUCCESSFUL="0 4 8"
# no update pending
UPDATE_REBOOT_PENDING="27"

log() {
    ts="$(date +'%Y-%m-%d %H:%M:%S')"
    echo "$ts - $*" >>"$UPDATE_STATE_FILE" 2>/dev/null || true
    logger -t fus-updater -- "$*" 2>/dev/null || true
}

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <device>"
    exit 1
fi
DEVICE="$1"
DEVNODE="/dev/$DEVICE"
MOUNT_POINT="${MOUNT_BASE}-$(basename "$DEVICE")"

# Never delete lock file — flock works on the inode, not the path.
exec 9>"$LOCK_FILE"
flock -n 9 || {
    log "Updater already running"
    exit 0
}

cleanup() {
    if [ -n "$TMP_PKG" ]; then rm -f "$TMP_PKG"; fi
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
        umount -l "$MOUNT_POINT"
    fi
    rmdir "$MOUNT_POINT" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

if [ ! -x "$FS_UPDATER_BIN" ]; then
    log "fs-updater binary not found at $FS_UPDATER_BIN"
    exit 1
fi

# Check for pending update state from previous run, and log it if found
return_state=0
$FS_UPDATER_BIN --update_reboot_state || return_state=$?
if [ "$return_state" -ne "$UPDATE_REBOOT_PENDING" ]; then
    log "Update pending, last reboot state (return_state=$return_state)"
    exit 0
fi

log "Updater started for $DEVNODE"

# Wait for kernel to finish creating the block device node.
WAIT_SECS=60
INTERVAL_MS=200
ELAPSED_MS=0

while ! [ -b "$DEVNODE" ]; do
    if [ "$ELAPSED_MS" -ge $((WAIT_SECS * 1000)) ]; then
        log "Device $DEVNODE not found as block device"
        exit 1
    fi
    sleep 0.2
    ELAPSED_MS=$((ELAPSED_MS + INTERVAL_MS))
done

FSTYPE="$(blkid -o value -s TYPE "$DEVNODE" 2>/dev/null || true)"
if [ -z "$FSTYPE" ]; then
    log "Cannot detect filesystem for $DEVNODE"
    exit 1
fi

mkdir -p "$MOUNT_POINT"
COUNT=0
while ! mount -t "$FSTYPE" -o "$MOUNT_OPTS" "$DEVNODE" "$MOUNT_POINT"; do
    COUNT=$((COUNT + 1))
    if [ "$COUNT" -ge 5 ]; then
        log "Mount failed for $DEVNODE"
        exit 1
    fi
    sleep 1
done

# Safe key=value parser — never source untrusted files from USB.
# Strips "export " prefix for backward compatibility.
CANDIDATE=""
CONFIG="$MOUNT_POINT/update_config"
UPDATE_TYPE=""
UPDATE_FILE=""
SCAN_FOR_UPDATE=""

if [ -f "$CONFIG" ]; then
    while IFS='=' read -r key value; do
        key="${key#export }"
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"
        case "$key" in
        UPDATE_FILE) UPDATE_FILE="$value" ;;
        UPDATE_TYPE) UPDATE_TYPE="$value" ;;
        SCAN_FOR_UPDATE) SCAN_FOR_UPDATE="$value" ;;
        *) ;;
        esac
    done <"$CONFIG"
fi

case "${UPDATE_TYPE:-}" in
fw) SCAN_EXT=".fw" ;;
app) SCAN_EXT=".app" ;;
*) SCAN_EXT=".fs" ;;
esac

if [ -n "$UPDATE_FILE" ]; then
    if [ -f "$MOUNT_POINT/$UPDATE_FILE" ]; then
        CANDIDATE="$MOUNT_POINT/$UPDATE_FILE"
    else
        log "UPDATE_FILE=$UPDATE_FILE specified but not found on device"
    fi
fi

# Scan is opt-in only — prevents accidental install from stale files.
if [ -z "$CANDIDATE" ] && [ "${SCAN_FOR_UPDATE:-}" = "yes" ]; then
    for f in "$MOUNT_POINT"/*"$SCAN_EXT"; do
        [ -f "$f" ] || continue
        CANDIDATE="$f"
        break
    done
fi

if [ -z "$CANDIDATE" ]; then
    log "No update file found"
    exit 0
fi

UPDATE_SIZE=$(stat -c%s "$CANDIDATE")
log "Update file: $CANDIDATE ($((UPDATE_SIZE / 1024 / 1024)) MB)"

# Copy to RAM so USB can be safely removed during update.
MEM_AVAIL=$(awk '/MemAvailable/ {print $2*1024}' /proc/meminfo)
MEM_AVAIL="${MEM_AVAIL:-0}"
if [ "$MEM_AVAIL" -gt $((UPDATE_SIZE * 2)) ]; then
    TMP_PKG="$TMP_DIR/$(basename "$CANDIDATE")"
    if cp -f "$CANDIDATE" "$TMP_PKG"; then
        if umount "$MOUNT_POINT"; then
            export UPDATE_STICK="$TMP_DIR"
            export UPDATE_FILE="$(basename "$TMP_PKG")"
            log "Using RAM copy for update"
        else
            log "Umount failed after RAM copy, falling back to USB"
            rm -f "$TMP_PKG"
            TMP_PKG=""
            export UPDATE_STICK="$MOUNT_POINT"
            export UPDATE_FILE="$(basename "$CANDIDATE")"
        fi
    else
        log "Copy to RAM failed, falling back to USB"
        export UPDATE_STICK="$MOUNT_POINT"
        export UPDATE_FILE="$(basename "$CANDIDATE")"
    fi
else
    export UPDATE_STICK="$MOUNT_POINT"
    export UPDATE_FILE="$(basename "$CANDIDATE")"
fi

# Only "fw" and "app" need --update_type; omit for standard .fs updates.
update_type='nok'
if [ -n "${UPDATE_TYPE:-}" ]; then
    case "$UPDATE_TYPE" in
    app | fw) update_type='ok' ;;
    *) update_type='nok' ;;
    esac
fi

log "Update type ${UPDATE_TYPE:-none} - $update_type"

# set to 0 to handle || operator correctly
return_state=0
$FS_UPDATER_BIN --automatic || return_state=$?

# Only reset return_state on successful apply — otherwise failure is masked.
for SUCCESS in $UPDATE_SUCCESSFUL; do
    if [ "$return_state" -eq "$SUCCESS" ]; then
        apply_state=0
        $FS_UPDATER_BIN --apply_update || apply_state=$?
        if [ "$apply_state" -eq 0 ]; then
            log "Update successful, applying (return_state=$return_state)"
            return_state=0
        else
            log "Update installed but apply failed (apply_state=$apply_state)"
        fi
        break
    fi
done

if [ "$return_state" -ne 0 ]; then
    log "Update failed (return_state=$return_state)"
fi
