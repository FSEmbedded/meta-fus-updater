#
# Copyright (C) 2025 F&S Elektronik Systeme GmbH
#
# This file is part of meta-fus-updater
#
# SPDX-License-Identifier: MIT
#
# Recipe for modifying volatile-binds to use tmpfs with specific sizes
#

# Flexible volatile-binds configuration with customizable paths and mount types
# Save as meta-yourlayer/recipes-core/volatile-binds/volatile-binds_%.bbappend

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Root directory for persistent storage - can be overridden in machine config
VOLATILE_PERSISTENT_ROOT ?= "/rw_fs/root"

# Define sizes for tmpfs mounts
VOLATILE_SIZE_var-cache ?= "24M"
VOLATILE_SIZE_var-log ?= "32M"
VOLATILE_SIZE_var-tmp ?= "16M"
VOLATILE_SIZE_var-lib ?= "32M"
VOLATILE_SIZE_var-spool ?= "16M"
VOLATILE_SIZE_srv ?= "16M"
VOLATILE_SIZE_tmp ?= "64M"

# Configure which directories should use which mount type
# Format: space-separated list of paths relative to root
VOLATILE_DIRS_TMPFS ?= "var/cache var/log var/tmp"
VOLATILE_DIRS_PERSISTENT ?= "var/lib var/spool srv"

SRC_URI += "file://mount-copybind-extended"

do_install:append() {
    # Replace the mount-copybind script with our enhanced version
    install -m 0755 ${WORKDIR}/mount-copybind-extended ${D}${base_sbindir}/mount-copybind
    
    # Process volatile binds to update service files
    printf "%b" "${VOLATILE_BINDS}" > "${WORKDIR}/volatile-binds.txt"
    
    while IFS= read -r bind || [ -n "$bind" ]; do
        bind=$(echo "${bind}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "${bind}" ] || [ "${bind:0:1}" = "#" ] && continue
        
        case "${bind}" in
            */*/*\ /*) ;;
            *) continue ;;
        esac
        
        spec=$(echo "${bind}" | cut -d' ' -f1)
        mountpoint=$(echo "${bind}" | cut -d' ' -f2-)
        relpath=$(echo "${mountpoint}" | sed 's,^/,,')
        sanitized=$(basename "${mountpoint}")
        
        service="${D}${systemd_system_unitdir}/var-volatile-${sanitized}.service"
        
        if [ -f "${service}" ]; then
            # Add environment variables to the service file with proper escaping
            sed -i -e '/\[Service\]/a Environment="MOUNT_COPYBIND_PERSISTENT_ROOT=${VOLATILE_PERSISTENT_ROOT}"' "${service}"
            
            # Determine mount type based on configuration
            if echo "${VOLATILE_DIRS_TMPFS}" | grep -q -w "${relpath}"; then
                # Configure as tmpfs
                sed -i -e '/\[Service\]/a Environment="MOUNT_COPYBIND_TYPE=tmpfs"' "${service}"
                
                # Get size from variable if defined - use proper sanitized name
                sanitized_var=$(echo "${relpath}" | tr '/' '-')
                eval size_var=\$VOLATILE_SIZE_${sanitized_var}
                if [ -n "${size_var}" ]; then
                    sed -i -e "/\[Service\]/a Environment=\"MOUNT_COPYBIND_SIZE=${size_var}\"" "${service}"
                fi
            elif echo "${VOLATILE_DIRS_PERSISTENT}" | grep -q -w "${relpath}"; then
                # Configure as persistent
                sed -i -e '/\[Service\]/a Environment="MOUNT_COPYBIND_TYPE=persistent"' "${service}"
            else
                # Default to overlay
                sed -i -e '/\[Service\]/a Environment="MOUNT_COPYBIND_TYPE=overlay"' "${service}"
            fi

            # Add dependency to ensure that /var/log is mounted before services using it
            if [ "${relpath}" != "var/log" ]; then  
                if echo "${relpath}" | grep -q "^var/log/"; then
                    sed -i -e '/\[Unit\]/a After=var-volatile-log.service' "${service}"
                    sed -i -e '/\[Unit\]/a Requires=var-volatile-log.service' "${service}"
                fi
            fi
        fi
    done < "${WORKDIR}/volatile-binds.txt"
    
    rm -f "${WORKDIR}/volatile-binds.txt"
}