# Copyright (C) 2024 F&S Elektronik Systeme GmbH
# Released under the GPLv2 license
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# includes the PATH_TO_FW_ENV_CONF* variables
require includes/system_paths.inc
# include offsets
require fw_env_offsets.inc

SRC_URI += "\
    file://fw_env.config.in \
    "

RDEPENDS:${PN} = "libubootenv"

# default devices
UBOOT_FW_ENV_MMC_DEV ?= "/dev/mmcblk0boot0"
UBOOT_FW_ENV_MMC_REDUNDANT_DEV ?= "/dev/mmcblk0boot1"
UBOOT_FW_ENV_NAND_DEV ?= "/dev/mtd0"
UBOOT_FW_ENV_NAND_REDUNDANT_DEV ?= "/dev/mtd0"

do_install() {

    install -d ${D}${sysconfdir}

    #
    # generate MMC config
    #
    sed \
        -e "s|@@DEV@@|${UBOOT_FW_ENV_MMC_DEV}|g" \
        -e "s|@@DEV_RED@@|${UBOOT_FW_ENV_MMC_REDUNDANT_DEV}|g" \
        -e "s|@@ENV_START@@|${UBOOT_FW_ENV_MMC_START}|g" \
        -e "s|@@ENV_SIZE@@|${UBOOT_FW_ENV_MMC_SIZE}|g" \
        -e "s|@@ENV_RED_START@@|${UBOOT_FW_ENV_MMC_REDUNDANT_START}|g" \
        -e "s|@@ENV_RED_SIZE@@|${UBOOT_FW_ENV_MMC_REDUNDANT_SIZE}|g" \
        ${WORKDIR}/fw_env.config.in \
        > ${D}${EMMC_UBOOT_ENV_PATH}

    chmod 0644 ${D}${EMMC_UBOOT_ENV_PATH}

    #
    # generate NAND config
    #
    sed \
        -e "s|@@DEV@@|${UBOOT_FW_ENV_NAND_DEV}|g" \
        -e "s|@@DEV_RED@@|${UBOOT_FW_ENV_NAND_REDUNDANT_DEV}|g" \
        -e "s|@@ENV_START@@|${UBOOT_FW_ENV_NAND_START}|g" \
        -e "s|@@ENV_SIZE@@|${UBOOT_FW_ENV_NAND_SIZE}|g" \
        -e "s|@@ENV_RED_START@@|${UBOOT_FW_ENV_NAND_REDUNDANT_START}|g" \
        -e "s|@@ENV_RED_SIZE@@|${UBOOT_FW_ENV_NAND_REDUNDANT_SIZE}|g" \
        -e "s|@@ERASE_SIZE@@|${UBOOT_FW_ENV_NAND_ERASE_SIZE}|g" \
        ${WORKDIR}/fw_env.config.in \
        > ${D}${NAND_UBOOT_ENV_PATH}

    chmod 0644 ${D}${NAND_UBOOT_ENV_PATH}
}
