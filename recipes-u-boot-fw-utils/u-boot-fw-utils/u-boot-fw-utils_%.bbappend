# create uboot tool fw_printenv
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=a2c678cfd4a4d97135585cad908541c6"

SRC_URI = "file://u-boot-2018.03-fus.tar.bz2 \
		   file://fw_env.config.mmc \
		   file://fw_env.config.nand \
"
S = "${WORKDIR}/u-boot-2018.03-fus"

do_install_append () {

	if [[ "${UBOOT_CONFIG}" == "emmc" ]]; then
		install -m 0644 ${WORKDIR}/fw_env.config.mmc ${D}${sysconfdir}/fw_env.config
	elif [[ "${UBOOT_CONFIG}" == "nand" ]]; then
		install -m 0644 ${WORKDIR}/fw_env.config.nand ${D}${sysconfdir}/fw_env.config
	else
		echo "UBOOT_CONFIG has not the right value (emmc|nand): ${UBOOT_CONFIG}"; exit 4
	fi
}

