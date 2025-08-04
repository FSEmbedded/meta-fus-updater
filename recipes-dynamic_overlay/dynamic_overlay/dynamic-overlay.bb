# Copyright (C) 2024 F&S Elektronik Systeme GmbH
# Released under the GPLv2 license
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

inherit cmake
require includes/system_paths.inc

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
DESCRIPTION = "dynamic-overlay"

SRCREV ?= "3726bd302587c8d215dd1b398096df2d19d54cfa"
DYNOL_SRC_URI ?= "git://github.com/FSEmbedded/dynamic-overlay.git"
DYNOL_GIT_BRANCH ?= "master"

SRC_URI = " \
    ${DYNOL_SRC_URI};protocol=https;branch=${DYNOL_GIT_BRANCH} \
    "

S = "${WORKDIR}/git"
PV = "+git${SRCPV}"

FILES:${PN} = " \
	/sbin/ \
	/sbin/preinit \
	/ramdisk_hw_conf \
"

DEPENDS += "\
	inicpp \
	libubootenv \
	zlib \
	jsoncpp \
	mtd-utils \
	util-linux \
"

RDEPENDS:${PN} += "\
	mtd-utils \
	util-linux \
"

# Set extra C-Make variables.
EXTRA_OECMAKE += " -DCMAKE_INSTALL_SBINDIR=/sbin"
EXTRA_OECMAKE += " -DRAUC_SYSTEM_CONF_PATH=${RAUC_SYSTEM_CONF_PATH}"
EXTRA_OECMAKE += " -DNAND_RAUC_SYSTEM_CONF_PATH=${NAND_RAUC_SYSTEM_CONF_PATH}"
EXTRA_OECMAKE += " -DEMMC_RAUC_SYSTEM_CONF_PATH=${EMMC_RAUC_SYSTEM_CONF_PATH}"
EXTRA_OECMAKE += " -DUBOOT_ENV_PATH=${UBOOT_ENV_PATH}"
EXTRA_OECMAKE += " -DNAND_UBOOT_ENV_PATH=${NAND_UBOOT_ENV_PATH}"
EXTRA_OECMAKE += " -DEMMC_UBOOT_ENV_PATH=${EMMC_UBOOT_ENV_PATH}"

# optional block for detection of update device
# Regular expression to detect boot device (mmc)
# EXTRA_OECMAKE += " -DPERSISTMEMORY_REGEX_EMMC="root=/dev/mmcblk[0-2]p[0-9]{1,3}""
# Regular expression to detect boot device (nand) with ubifs.
# EXTRA_OECMAKE += " -DPERSISTMEMORY_REGEX_NAND="root=/dev/ubiblock0_[0-1]""
# add other data partition name
# must be same name in layout of update divice
# EXTRA_OECMAKE += " -DPERSISTMEMORY_DEVICE_NAME="data""

# set the define to the block number of the secure partition
# dynamic overlay uses raw read to get keys and
# configuration for adu agent. dd uses to read data.
# TODO: add new wic configuration with additional partition
EXTRA_OECMAKE += " -DEMMC_SECURE_PART_BLK_NR=16384"
# TODO: add possibility to use mmc replay protected memory block (rpmb)
