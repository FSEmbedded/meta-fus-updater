# create uboot tool fw_printenv
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "file://u-boot-2018.03-fus.tar.bz2 \
		   file://fw_env.config.mmc \
		   file://fw_env.config.nand \
"
S = "${WORKDIR}/u-boot-2018.03-fus"

do_install_append () {
	install -m 0644 ${WORKDIR}/fw_env.config.mmc ${D}${sysconfdir}/fw_env.config.mmc
	install -m 0644 ${WORKDIR}/fw_env.config.nand ${D}${sysconfdir}/fw_env.config.nand
	rm -f ${D}${sysconfdir}/fw_env.config
}
