SUMMARY = "Create signed application package"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit setuptools3 native

DEPENDS += "python3-native"
DEPENDS += "python3-pycryptodome-native"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SECTION = "devel/python"
SRC_URI = "\
	file://setup.py \
	file://createSignedPackage \
"
S = "${WORKDIR}"

INSANE_SKIP:${PN} += "build-deps"

BBCLASSEXTEND = "native"
