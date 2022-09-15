inherit cmake
require includes/system_paths.inc

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
DESCRIPTION = "dynamic-overlay"
LICENSE = "CLOSED"

SRC_URI = "file://dynamic_overlay.tar.gz \
"
S = "${WORKDIR}/dynamic_overlay"

FILES_${PN} = " \
	/sbin/ \
	/sbin/preinit \
	/ramdisk_hw_conf \
"

DEPENDS = "\
	inicpp \
	libubootenv \
	zlib \
	jsoncpp \
"
# Set extra C-Make variables.
EXTRA_OECMAKE += " -DRAUC_SYSTEM_CONF_PATH=${RAUC_SYSTEM_CONF_PATH}"
EXTRA_OECMAKE += " -DNAND_RAUC_SYSTEM_CONF_PATH=${NAND_RAUC_SYSTEM_CONF_PATH}"
EXTRA_OECMAKE += " -DEMMC_RAUC_SYSTEM_CONF_PATH=${EMMC_RAUC_SYSTEM_CONF_PATH}"
EXTRA_OECMAKE += " -DUBOOT_ENV_PATH=${UBOOT_ENV_PATH}"
EXTRA_OECMAKE += " -DNAND_UBOOT_ENV_PATH=${NAND_UBOOT_ENV_PATH}"
EXTRA_OECMAKE += " -DEMMC_UBOOT_ENV_PATH=${EMMC_UBOOT_ENV_PATH}"
