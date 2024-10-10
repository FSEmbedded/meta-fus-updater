DESCRIPTION = "Script for mounting applications during boot"
RDEPENDS:${PN} = "dynamic-overlay busybox"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://preinit.sh"
S = "${WORKDIR}"

do_install:append() {
	install -d ${D}/sbin
	install -m 0555 ${S}/preinit.sh ${D}/sbin
}

PACKAGES += "${PN}-2-stage-boot"
FILES:${PN}-2-stage-boot = "/sbin/preinit.sh"
