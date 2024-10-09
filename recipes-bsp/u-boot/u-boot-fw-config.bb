# Copyright (C) 2024 F&S Elektronik Systeme GmbH
# Released under the GPLv2 license
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# includes the PATH_TO_FW_ENV_CONF* variables
require includes/system_paths.inc

SRC_URI += "\
    file://fw_env.config.mmc \
    file://fw_env.config.nand \
    "

S = "${WORKDIR}"
RDEPENDS:${PN} = "libubootenv"

do_install () {
    install -d ${D}${sysconfdir}
    if [ -e ${WORKDIR}/fw_env.config.nand ] ; then
        install -m 0644 ${S}/fw_env.config.nand ${D}${NAND_UBOOT_ENV_PATH}
    fi
    if [ -e ${WORKDIR}/fw_env.config.mmc ] ; then
        install -m 0644 ${S}/fw_env.config.mmc ${D}${EMMC_UBOOT_ENV_PATH}
    fi
}
