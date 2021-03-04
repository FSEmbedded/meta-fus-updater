inherit pypi setuptools3

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SUMMARY = "FS-Update command line interface"
SECTION = "devel/python"
SRC_URI = "file://fs_updater_cli-0.1.0.tar.gz"

S = "${WORKDIR}/fs_updater_cli-0.1.0"
LICENSE = "CLOSED"

RDEPENDS_${PN} += "python3-fs-updater-lib"
RDEPENDS_${PN} += "python3-setuptools"

