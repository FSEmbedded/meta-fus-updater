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

python () {
    if d.getVar("FIRMWARE_VERSION") == None:
        bb.fatal("FIRMWARE_VERSION is not defined in local.conf!")
    else:
        try:
            int(d.getVar("FIRMWARE_VERSION"))
        except:
            var = d.getVar("FIRMWARE_VERSION")
            bb.fatal(f"FIRMWARE_VERSION :\"{var} is not convertable into int")
}

do_install_prepend() {
	if [[ ${MEMORY_TYPE} == "emmc" ]]; then
		cp ${WORKDIR}/system.conf.mmc ${WORKDIR}/system.conf
	elif [[ ${MEMORY_TYPE} == "nand" ]]; then
		cp ${WORKDIR}/system.conf.nand ${WORKDIR}/system.conf
	else
		bbfatal "MEMORY_TYPE ist not configured properly: allowed content is (emmc|nand); set is: $MEMORY_TYPE"
		exit 1
	fi


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

