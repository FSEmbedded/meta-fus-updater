# create uboot tool fw_printenv
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# includes the PATH_TO_FW_ENV_CONF* variables
require includes/system_paths.inc

SRC_URI = "file://fw_env.config.mmc \
		   file://fw_env.config.nand \
"

S = "${WORKDIR}"

RDEPENDS_${PN} = "libubootenv"
LICENSE = "CLOSED"

do_install () {
	mkdir -p ${D}/etc
	install -m 0644 ${S}/fw_env.config.nand ${D}${NAND_UBOOT_ENV_PATH}
	install -m 0644 ${S}/fw_env.config.mmc ${D}${EMMC_UBOOT_ENV_PATH}
}
