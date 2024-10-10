# Copyright (C) 2024 F&S Elektronik Systeme GmbH
# Released under the GPLv2 license
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

SUMMARY = "FS update Framework library"
SECTION = "libs"

inherit cmake

SRCREV ?= ""
FSUPLIB_SRC_URI ?= ""
FSUPLIB_GIT_BRANCH ?= "master"

SRC_URI = " \
    ${FSUPLIB_SRC_URI};protocol=https;branch=${FSUPLIB_GIT_BRANCH} \
    "

S = "${WORKDIR}/git"
PV = "+git${SRCPV}"

DEPENDS = " \
    libubootenv \
    botan \
    jsoncpp \
    zlib \
    inicpp \
    "

RDEPENDS:${PN} = "\
		libubootenv \
		zlib \
		botan \
"
EXTRA_OECMAKE += "-DBOTAN2:STRING=${STAGING_DIR_TARGET}/usr/include/botan-2/"
