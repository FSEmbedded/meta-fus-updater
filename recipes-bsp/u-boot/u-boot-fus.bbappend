FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

#Remove U-Boot patch that would make the Kernel partition ro
SRC_URI:remove = "file://0001-Set-file-system-RW.patch"

SUPPORTED_MACHINES ?= "fsimx8mp fsimx8mm"

do_configure:append() {
    for mach in ${SUPPORTED_MACHINES}; do
        # Enable fsup framework support if not available
        if [ "${MACHINE}" = "${mach}" ]; then
            if ! grep -q 'CONFIG_FS_UPDATE_SUPPORT=y' $config; then
                echo "CONFIG_FS_UPDATE_SUPPORT=y" >> ${B}/.config
                yes "" | oe_runmake oldconfig
            fi
        fi
    done
}
