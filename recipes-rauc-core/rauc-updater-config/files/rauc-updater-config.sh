#!/bin/sh
# File: rauc-updater-config.sh
# Description: Script to update fw_env.conf and RAUC system.conf
#     # Method 1: From kernel command line
#     # Method 2: From root mountpoint
#     # Method 3: Check all potential mmcblk devices
#     # Method 4: Fallback if dynamic detection fails

# Configuration paths
FW_ENV_CONFIG="/etc/fw_env.config"
FW_ENV_CONFIG_BACKUP="$FW_ENV_CONFIG.bak"
RAUC_CONFIG="/etc/rauc/system.conf"
RAUC_CONFIG_BACKUP="$RAUC_CONFIG.bak"
TEMP_CONFIG=""
TEMP_FW_CONFIG=""

# Default file permissions
DEFAULT_PERM="644"

# Device search range configuration
# Minimum and maximum device numbers for mmcblk devices
MIN_DEVICE_NUM=0
MAX_DEVICE_NUM=15
# Support for devices up to mmcblk15

# Set up logging
log()
{
    printf "%s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>/var/log/rauc-config-update.log
}

# Initialize environment
init()
{
    set -e
    TEMP_CONFIG=$(mktemp)
    TEMP_FW_CONFIG=$(mktemp)
    trap cleanup INT TERM

    # Check if fw_env.conf exists
    if [ ! -f "$FW_ENV_CONFIG" ]; then
        log "ERROR: $FW_ENV_CONFIG not found"
        return 1
    fi

    # Check if system.conf exists
    if [ ! -f "$RAUC_CONFIG" ]; then
        log "ERROR: $RAUC_CONFIG not found"
        return 1
    fi

    return 0
}

# Clean up on errors
cleanup()
{
    for tmp_file in "$TEMP_CONFIG" "$TEMP_FW_CONFIG"; do
        if [ -n "$tmp_file" ] && [ -f "$tmp_file" ]; then
            rm -f "$tmp_file"
        fi
    done
    log "Script was interrupted or failed"
    exit 1
}

# Detect boot device (multiple methods)
detect_boot_device()
{
    log "Starting boot device detection..."

    # Method 1: From kernel command line
    if grep -q "root=/dev/mmcblk" /proc/cmdline; then
        DETECTED=$(grep "root=/dev/mmcblk[0-9]\\{1,2\\}" /proc/cmdline | sed 's/.*root=\/dev\/\(mmcblk[0-9]\{1,2\}\).*/\1/')
        log "Boot device found via kernel command line: $DETECTED"
        echo "$DETECTED"
        return 0
    fi

    # Method 2: From root mountpoint
    ROOT_MOUNT=$(mount | grep " / " | cut -d' ' -f1)
    if echo "$ROOT_MOUNT" | grep -q "/dev/mmcblk[0-9]\\{1,2\\}"; then
        DETECTED=$(echo "$ROOT_MOUNT" | sed 's/\/dev\/\(mmcblk[0-9]\{1,2\}\).*/\1/')
        log "Boot device found via root mountpoint: $DETECTED"
        echo "$DETECTED"
        return 0
    fi

    # Method 3: Check all potential mmcblk devices
    if [ -d "/dev" ]; then
        # Use ls to find all mmcblk devices dynamically
        for DEV in $(ls /dev/mmcblk* 2>/dev/null | grep -E "/dev/mmcblk[0-9]{1,2}$" | sed 's/\/dev\///'); do
            if [ -b "/dev/$DEV" ]; then
                log "Boot device found via existing device: $DEV"
                echo "$DEV"
                return 0
            fi
        done
    else
        # Fallback if dynamic detection fails
        for i in $(seq $MIN_DEVICE_NUM $MAX_DEVICE_NUM); do
            DEV="mmcblk$i"
            if [ -b "/dev/$DEV" ]; then
                log "Boot device found via existing device: $DEV"
                echo "$DEV"
                return 0
            fi
        done
    fi

    # No detection successful
    log "ERROR: Could not detect boot device"
    return 1
}

# Process a file and check if update is needed
process_config()
{
    local config_type="$1" # "fw_env" or "rauc"
    local boot_device="$2"
    local source_file="$3"
    local dest_file="$4"
    local backup_file="$5"
    local temp_file="$6"
    local needs_update=0
    local device_check_file=$(mktemp)
    local pattern

    log "Checking if $config_type configuration update is needed..."

    # Pattern depends on config type
    if [ "$config_type" = "rauc" ]; then
        pattern="device=/dev/mmcblk"
    else
        pattern="/dev/mmcblk"
    fi

    # Extract device entries to check
    grep "$pattern" "$source_file" >"$device_check_file" || true

    # Check if any entry doesn't match the boot device
    while IFS= read -r line; do
        # Extract device from line based on config type
        if [ "$config_type" = "rauc" ]; then
            device_pattern=$(echo "$line" | sed 's/.*device=\/dev\/\(mmcblk[0-9]\{1,2\}\).*/\1/')
        else
            device_pattern=$(echo "$line" | sed 's/\/dev\/\(mmcblk[0-9]\{1,2\}\).*/\1/')
        fi

        # If device doesn't match boot device, update needed
        if [ "$device_pattern" != "$boot_device" ]; then
            log "Found $config_type entry with device $device_pattern, update needed"
            needs_update=1
            break
        fi
    done <"$device_check_file"

    # Clean up temp file
    rm -f "$device_check_file"

    # If no update needed, return early
    if [ "$needs_update" -eq 0 ]; then
        log "All $config_type device entries already match $boot_device, no update needed"
        return 2
    fi

    # Create backup of target file
    cp -f "$source_file" "$backup_file"
    log "Backup created: $backup_file"

    # Update configuration with boot device
    log "Updating $config_type configuration with boot device: $boot_device"

    # Process file lines based on config type
    if [ "$config_type" = "rauc" ]; then
        # RAUC config specific processing
        while IFS= read -r line; do
            if echo "$line" | grep -q "device=/dev/mmcblk"; then
                echo "$line" | sed "s/\/dev\/mmcblk[0-9]\{1,2\}/\/dev\/$boot_device/g"
            else
                echo "$line"
            fi
        done <"$source_file" >"$temp_file"
    else
        # fw_env.conf specific processing
        while IFS= read -r line; do
            if echo "$line" | grep -q "^#"; then
                echo "$line"
            elif echo "$line" | grep -q "/dev/mmcblk"; then
                echo "$line" | sed "s/\/dev\/mmcblk[0-9]\{1,2\}\(boot[0-9]*\)\?/\/dev\/$boot_device\1/g"
            else
                echo "$line"
            fi
        done <"$source_file" >"$temp_file"
    fi

    # Apply changes with preserved attributes
    apply_changes "$temp_file" "$dest_file"

    return 0
}

# Apply changes preserving attributes
apply_changes()
{
    local source_file="$1"
    local target_file="$2"
    local orig_perms="$DEFAULT_PERM"
    local orig_owner

    if command -v stat >/dev/null 2>&1; then
        # Get original permissions and ownership if possible
        orig_perms=$(stat -c "%a" "$target_file" 2>/dev/null || stat -f "%p" "$target_file" | cut -c 4-6)
        orig_owner=$(stat -c "%u:%g" "$target_file" 2>/dev/null || echo "$(id -u):$(id -g)")

        # Apply content with preserved attributes
        cat "$source_file" >"$target_file"
        chmod "$orig_perms" "$target_file" 2>/dev/null || chmod "$DEFAULT_PERM" "$target_file"
        chown "$orig_owner" "$target_file" 2>/dev/null || true
    else
        # Simple fallback
        cat "$source_file" >"$target_file"
        chmod "$DEFAULT_PERM" "$target_file"
    fi

    # Remove temporary file
    rm -f "$source_file"

    return 0
}

# Restart RAUC service
restart_rauc()
{
    # Try systemd first
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet rauc 2>/dev/null; then
            log "Restarting RAUC service (systemd)"
            systemctl restart rauc || log "Warning: Could not restart RAUC service"
            return 0
        else
            log "RAUC service not active, trying to start it"
            systemctl start rauc || log "Warning: Could not start RAUC service"
            return 0
        fi
    fi

    # Try init.d as fallback
    if [ -x /etc/init.d/rauc ]; then
        log "Restarting RAUC service (init.d)"
        /etc/init.d/rauc restart || log "Warning: Could not restart RAUC service"
        return 0
    fi

    log "No RAUC service found or not started"
    return 1
}

# Resolve symlinks
resolve_path()
{
    local config_path="$1"
    local resolved_path

    if [ -L "$config_path" ]; then
        resolved_path=$(readlink -f "$config_path" 2>/dev/null || readlink "$config_path")
        log "$(basename "$config_path") is a symlink to $resolved_path"
        echo "$resolved_path"
    else
        echo "$config_path"
    fi
}

# Main function
main()
{
    local update_needed=0

    # Initialization
    if ! init; then
        exit 1
    fi

    # Detect boot device
    BOOT_DEVICE=$(detect_boot_device 2>/dev/null)
    if [ -z "$BOOT_DEVICE" ]; then
        log "Could not detect boot device"
        cleanup
    fi

    # Resolve symlinks
    FW_ENV_TARGET_CONFIG=$(resolve_path "$FW_ENV_CONFIG")
    RAUC_TARGET_CONFIG=$(resolve_path "$RAUC_CONFIG")

    # First: Update fw_env.conf configuration
    if process_config "fw_env" "$BOOT_DEVICE" "$FW_ENV_TARGET_CONFIG" \
        "$FW_ENV_TARGET_CONFIG" "$FW_ENV_CONFIG_BACKUP" "$TEMP_FW_CONFIG"; then
        log "Successfully updated fw_env.conf"
        update_needed=1
    elif [ "$?" -eq 2 ]; then
        log "No fw_env.conf changes needed"
        rm -f "$TEMP_FW_CONFIG"
    else
        log "Error during fw_env.conf update"
        cleanup
    fi

    # Second: Update RAUC configuration
    if process_config "rauc" "$BOOT_DEVICE" "$RAUC_TARGET_CONFIG" \
        "$RAUC_TARGET_CONFIG" "$RAUC_CONFIG_BACKUP" "$TEMP_CONFIG"; then
        log "Successfully updated RAUC configuration"
        update_needed=1
    elif [ "$?" -eq 2 ]; then
        log "No RAUC configuration changes needed"
        rm -f "$TEMP_CONFIG"
    else
        log "Error during RAUC configuration update"
        cleanup
    fi

    # Restart RAUC service if any changes were made
    if [ "$update_needed" -eq 1 ]; then
        restart_rauc
    fi

    log "Script executed successfully"
    exit 0
}

# Execute script
main "$@"
