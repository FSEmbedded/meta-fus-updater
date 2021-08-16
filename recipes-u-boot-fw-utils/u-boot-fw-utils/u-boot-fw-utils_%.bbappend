# create uboot tool fw_printenv
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# includes the PATH_TO_FW_ENV_CONF* variables
require includes/system_paths.inc

SRC_URI = "file://u-boot-2018.03-fus.tar.bz2 \
		   file://fw_env.config.mmc \
		   file://fw_env.config.nand \
"
S = "${WORKDIR}/u-boot-2018.03-fus"

do_install_append () {
	install -m 0644 ${WORKDIR}/fw_env.config.nand ${D}${NAND_UBOOT_ENV_PATH}
	install -m 0644 ${WORKDIR}/fw_env.config.mmc ${D}${EMMC_UBOOT_ENV_PATH}
	rm -f ${D}${UBOOT_ENV_PATH}
}
