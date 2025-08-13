DESCRIPTION = "Script for mounting applications during boot"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://preinit.sh"
S = "${WORKDIR}"

RDEPENDS:${PN} += "dynamic-overlay busybox"

do_install:append() {
	install -d ${D}${sbindir}
	install -m 0555 ${S}/preinit.sh ${D}${sbindir}/preinit.sh
}

FILES:${PN} = "${sbindir}/preinit.sh"
