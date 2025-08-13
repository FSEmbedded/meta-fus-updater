FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# includes the PATH_TO_SYSTEM_CONF* variables
require includes/system_paths.inc

RDEPENDS:${PN} = " rauc-mark-good"
DEPENDS += "squashfs-tools-native rauc-native"

SRC_URI = " \
	file://system.conf.mmc \
	file://system.conf.nand \
"

CERT_PURPOSE = "system"
inherit cert-handler

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

# overwrite default installation to disable warnings
# use own structure to copy system.conf.[bootdevice] configurations
# and keyring file
do_install() {

    sed -i "s|@@RAUC_KEYRING_PATH@@|keyring.pem|g" ${WORKDIR}/system.conf.mmc
    sed -i "s|@@RAUC_KEYRING_PATH@@|keyring.pem|g" ${WORKDIR}/system.conf.nand

    install -d ${D}${sysconfdir}/rauc
    install -m 0644 ${WORKDIR}/system.conf.nand ${D}${NAND_RAUC_SYSTEM_CONF_PATH}
    install -m 0644 ${WORKDIR}/system.conf.mmc ${D}${EMMC_RAUC_SYSTEM_CONF_PATH}
    install -m 0644 ${CERT_BASE_DIR}/${FUS_BUILD_VARIANT}/root/root.cert.pem \
         ${D}${sysconfdir}/rauc/keyring.pem
    rm -f ${D}${RAUC_SYSTEM_CONF_PATH}
    echo "${FIRMWARE_VERSION}" > ${D}${sysconfdir}/fw_version
}

FILES:${PN} += "\
    /rw_fs/root \
    ${sysconfdir}/fw_version \
    "
