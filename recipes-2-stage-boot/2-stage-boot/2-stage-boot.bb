DESCRIPTION = "Script for mounting applications during boot"
RDEPENDS_${PN} = "dynamic-overlay busybox"
LICENSE = "CLOSED"

FILESEXTRAPATHS_prepend := "${THISDIR}:"


SRC_URI = "file://preinit.sh"
S = "${WORKDIR}/"

FILES_${PN} = "/sbin \
	/sbin/preinit.sh \
"

do_install() {
	install -d ${D}/sbin
	install -m 0555 ${S}/preinit.sh ${D}/sbin
}
