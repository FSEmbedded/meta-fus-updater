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
	if [[ ${UBOOT_CONFIG} == "emmc" ]]; then
		cp ${WORKDIR}/system.conf.mmc ${WORKDIR}/system.conf
	elif [[ ${UBOOT_CONFIG} == "nand" ]]; then
		cp ${WORKDIR}/system.conf.nand ${WORKDIR}/system.conf
	else
		bbfatal "UBOOT_CONFIG ist not configured properly: allowed content is (emmc|nand); set is: $UBOOT_CONFIG"
		exit 1
	fi


}

do_install_append() {
	install -d ${D}${sysconfdir}/rauc/bundle
	echo "${FIRMWARE_VERSION}" > ${D}${sysconfdir}/fw_version
}

FILES_${PN} += "\
  /rw_fs/root \
  ${sysconfdir}/rauc/bundle \
  ${sysconfdir}/fw_version \
"

