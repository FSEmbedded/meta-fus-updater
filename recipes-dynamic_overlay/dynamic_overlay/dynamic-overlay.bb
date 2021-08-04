inherit cmake

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
DESCRIPTION = "dynamic-overlay"
LICENSE = "CLOSED"

SRC_URI = "file://dynamic_overlay.tar.gz \
"
S = "${WORKDIR}/dynamic_overlay"


FILES_${PN} = " \
	/sbin/ \
	/sbin/preinit \
"

DEPENDS = "\
	inicpp \
	libubootenv \
	zlib \
"

