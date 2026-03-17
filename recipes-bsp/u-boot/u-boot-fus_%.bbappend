FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

#Remove U-Boot patch that would make the Kernel partition ro
SRC_URI:remove = "file://0001-Set-file-system-RW.patch"

SRC_URI:append:fsimx93 = " \
    file://enable-features.cfg \
    "
