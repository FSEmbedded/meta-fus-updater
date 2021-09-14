inherit bin_package application
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SUMMARY = "Copy overlay.ini template to your application"

SRC_URI = "\
	file://overlay.ini \
"
S = "${WORKDIR}"

LICENSE = "CLOSED"

do_install () {
	install -d ${D}
	install -m 0444 ${WORKDIR}/overlay.ini ${D}
}
