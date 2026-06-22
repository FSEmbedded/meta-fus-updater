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

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Root directory for persistent storage - can be overridden in machine config
VOLATILE_PERSISTENT_ROOT ?= "${FUS_PERSISTENT_ROOT}"

# Define sizes for tmpfs mounts - using underscores for variable names
VOLATILE_SIZE_var_cache ?= "24M"
VOLATILE_SIZE_var_log ?= "32M"
VOLATILE_SIZE_var_tmp ?= "16M"
VOLATILE_SIZE_var_lib ?= "32M"
VOLATILE_SIZE_var_spool ?= "16M"
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
    
    # Ensure persistent root directory will be available
    install -d ${D}${VOLATILE_PERSISTENT_ROOT}

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
            # Add environment variables to the service file
            sed -i '/\[Service\]/a Environment="MOUNT_COPYBIND_PERSISTENT_ROOT=${VOLATILE_PERSISTENT_ROOT}"' "${service}"
            
            # Determine mount type based on configuration
            if echo "${VOLATILE_DIRS_TMPFS}" | grep -q -w "${relpath}"; then
                # Configure as tmpfs
                sed -i '/\[Service\]/a Environment="MOUNT_COPYBIND_TYPE=tmpfs"' "${service}"

                # Get size from variable if defined - use proper variable name mapping
                sanitized_var=$(echo "${relpath}" | tr '/' '_')

                # Use proper variable name evaluation
                case "${sanitized_var}" in
                    var_cache) size_var="${VOLATILE_SIZE_var_cache}" ;;
                    var_log) size_var="${VOLATILE_SIZE_var_log}" ;;
                    var_tmp) size_var="${VOLATILE_SIZE_var_tmp}" ;;
                    var_lib) size_var="${VOLATILE_SIZE_var_lib}" ;;
                    var_spool) size_var="${VOLATILE_SIZE_var_spool}" ;;
                    srv) size_var="${VOLATILE_SIZE_srv}" ;;
                    tmp) size_var="${VOLATILE_SIZE_tmp}" ;;
                    *) size_var="" ;;
                esac
                
                if [ -n "${size_var}" ]; then
                    sed -i "/\[Service\]/a Environment=\"MOUNT_COPYBIND_SIZE=${size_var}\"" "${service}"
                fi

            elif echo "${VOLATILE_DIRS_PERSISTENT}" | grep -q -w "${relpath}"; then
                # Configure as persistent
                sed -i '/\[Service\]/a Environment="MOUNT_COPYBIND_TYPE=persistent"' "${service}"
            else
                # Default to overlay
                sed -i '/\[Service\]/a Environment="MOUNT_COPYBIND_TYPE=overlay"' "${service}"
            fi

            # Add dependency to ensure that /var/log is mounted before services using it
            if [ "${relpath}" != "var/log" ]; then  
                if echo "${relpath}" | grep -q "^var/log/"; then
                    sed -i '/\[Unit\]/a After=var-volatile-log.service' "${service}"
                    sed -i '/\[Unit\]/a Requires=var-volatile-log.service' "${service}"
                fi
            fi

            # Ensure persistent directories have proper dependencies
            if echo "${VOLATILE_DIRS_PERSISTENT}" | grep -q -w "${relpath}"; then
                # Add dependency on filesystem that contains persistent root
                sed -i '/\[Unit\]/a RequiresMountsFor=${VOLATILE_PERSISTENT_ROOT}' "${service}"
            fi
        fi
    done < "${WORKDIR}/volatile-binds.txt"
    
    rm -f "${WORKDIR}/volatile-binds.txt"
}

# Ensure the persistent root directory is created at runtime if needed
pkg_postinst:${PN}:append() {
    if [ -n "$D" ]; then
        # This is during build, create the directory structure
        install -d $D${VOLATILE_PERSISTENT_ROOT}/overlay
        install -d $D${VOLATILE_PERSISTENT_ROOT}/work
    else
        # This is on target, ensure runtime directory exists
        mkdir -p ${VOLATILE_PERSISTENT_ROOT}/overlay
        mkdir -p ${VOLATILE_PERSISTENT_ROOT}/work
    fi
}

# Add runtime dependencies
RDEPENDS:${PN} += "util-linux-mount"

# Ensure the package creates the persistent root
FILES:${PN} += "${VOLATILE_PERSISTENT_ROOT}"
