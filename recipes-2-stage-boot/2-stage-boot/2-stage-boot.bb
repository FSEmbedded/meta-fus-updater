SUMMARY = "Script for mounting applications during boot"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://preinit.sh"
S = "${WORKDIR}"

RDEPENDS:${PN} += "dynamic-overlay busybox"

do_install:append() {
	install -d ${D}${sbindir}
	install -m 0555 ${S}/preinit.sh ${D}${sbindir}/preinit.sh
}

FILES:${PN} = "${sbindir}/preinit.sh"
