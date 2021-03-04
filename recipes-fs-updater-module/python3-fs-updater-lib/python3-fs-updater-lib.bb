inherit pypi setuptools3

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SUMMARY = "FS-Update library"
SECTION = "devel/python"
SRC_URI = "file://fs_updater_lib-0.1.0.tar.gz"

S = "${WORKDIR}/fs_updater_lib-0.1.0"
LICENSE = "CLOSED"

RDEPENDS_${PN} += "python3-requests"
RDEPENDS_${PN} += "python3-cryptography"
