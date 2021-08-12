FILESEXTRAPATHS_prepend := "${THISDIR}/openssl:"
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# set path to the rauc keyring, which is installed in the image
RAUC_KEYRING_FILE = "rauc.cert.pem"

RDEPENDS_${PN} = " rauc-mark-good"
DEPENDS = "squashfs-tools-native rauc-native "

SRC_URI_append := " \
	file://system.conf.mmc \
	file://system.conf.nand \
	file://rauc.cert.pem \
"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# This is currently not used by FS-Update, but the additional adu-agent
# for cloud updates uses this to determine if an update has already been installed.
FIRMWARE_VERSION ?= "20211012"

python () {
    if d.getVar("FIRMWARE_VERSION") == None:
        bb.fatal("FIRMWARE_VERSION is not defined!")
    else:
        try:
            int(d.getVar("FIRMWARE_VERSION"))
        except:
            var = d.getVar("FIRMWARE_VERSION")
            bb.fatal(f"FIRMWARE_VERSION :\"{var} is not convertable into int")
}

do_install_append() {
	install -m 0644 ${WORKDIR}/system.conf.mmc ${D}${sysconfdir}/rauc/system.conf.mmc
	install -m 0644 ${WORKDIR}/system.conf.nand ${D}${sysconfdir}/rauc/system.conf.nand
	rm -f ${D}${sysconfdir}/rauc/system.conf
}

#unset SYSTEMD_SERVICE_${PN}-mark-good
#unset INITSCRIPT_PACKAGES
#unset INITSCRIPT_NAME_${PN}-mark-good
#unset INITSCRIPT_PARAMS_${PN}-mark-good
#unset RRECOMMENDS_${PN}
#unset FILES_${PN}-mark-good

#PACKAGES_remove = "${PN}-mark-good"
#RDEPENDS_remove = "${PN}-mark-good"
#SYSTEMD_PACKAGES_remove = "${PN}-mark-good"
#INITSCRIPT_NAME = "dummy"
#IMAGE_INSTALL_remove = "${PN}-mark-good"
#RRECOMMENDS_${PN}_remove = "${PN}-mark-good"

do_install_append() {
	install -d ${D}${sysconfdir}/rauc/bundle
	echo "${FIRMWARE_VERSION}" > ${D}${sysconfdir}/fw_version
#	rm  ${D}${systemd_unitdir}/system/rauc-mark-good.service
#	rm  ${D}${sysconfdir}/init.d/rauc-mark-good
}

FILES_${PN} += "\
  /rw_fs/root \
  ${sysconfdir}/rauc/bundle \
  ${sysconfdir}/fw_version \
"
