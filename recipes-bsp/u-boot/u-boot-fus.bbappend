FILESEXTRAPATHS_prepend := "${THISDIR}/u-boot-fus:"

SRC_URI += " file://0001-enable-fus-update-support.patch"

#Remove U-Boot patch that would make the Kernel partition ro
SRC_URI_remove = "file://0001-Set-file-system-RW.patch"
