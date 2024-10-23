
FILESEXTRAPATHS:prepend := "${THISDIR}/openssl:"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# includes the PATH_TO_SYSTEM_CONF* variables
require includes/system_paths.inc

# set path to the rauc keyring, which is installed in the image
RAUC_KEYRING_FILE = "rauc.cert.pem"

RDEPENDS:${PN} = " rauc-mark-good"
DEPENDS = "squashfs-tools-native rauc-native "

SRC_URI:append := " \
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

do_install:append() {
    install -m 0644 ${WORKDIR}/system.conf.nand ${D}${NAND_RAUC_SYSTEM_CONF_PATH}
    install -m 0644 ${WORKDIR}/system.conf.mmc ${D}${EMMC_RAUC_SYSTEM_CONF_PATH}
    rm -f ${D}${RAUC_SYSTEM_CONF_PATH}
    install -d ${D}${sysconfdir}/rauc/bundle
    echo "${FIRMWARE_VERSION}" > ${D}${sysconfdir}/fw_version
}

FILES:${PN} += "\
    /rw_fs/root \
    ${sysconfdir}/rauc/bundle \
    ${sysconfdir}/fw_version \
    "
