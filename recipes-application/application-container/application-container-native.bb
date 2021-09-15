inherit pypi setuptools3 native

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SUMMARY = "Create signed application package"
SECTION = "devel/python"
SRC_URI = "\
	file://setup.py \
	file://createSignedPackage \
"
S = "${WORKDIR}"

LICENSE = "CLOSED"

RDEPENDS_${PN} = "\
	python3-native \
	python3-pycryptodome-native \
"
INSANE_SKIP_${PN} += "build-deps"
