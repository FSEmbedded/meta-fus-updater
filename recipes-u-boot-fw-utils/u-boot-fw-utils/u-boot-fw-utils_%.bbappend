# create uboot tool fw_printenv
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "file://u-boot-2018.03-fus.tar.bz2 \
		   file://fw_env.config.mmc \
		   file://fw_env.config.nand \
"
S = "${WORKDIR}/u-boot-2018.03-fus"

do_install_append () {

	if [[ "${MEMORY_TYPE}" == "emmc" ]]; then
		install -m 0644 ${WORKDIR}/fw_env.config.mmc ${D}${sysconfdir}/fw_env.config
	elif [[ "${MEMORY_TYPE}" == "nand" ]]; then
		install -m 0644 ${WORKDIR}/fw_env.config.nand ${D}${sysconfdir}/fw_env.config
	else
		echo "MEMORY_TYPE is not configured properly: allowed content is (emmc|nand); set is: ${MEMORY_TYPE}"; exit 4
	fi
}

