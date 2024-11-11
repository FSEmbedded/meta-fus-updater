# Copyright (C) 2024 F&S Elektronik Systeme GmbH
# Released under the GPLv2 license
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

SUMMARY = "FS update Framework library"
SECTION = "libs"

inherit cmake

SRCREV ?= "6ccd1ff23a01410f07a0d39464abf6eb66f3469f"
FSUPLIB_SRC_URI ?= "git://github.com/FSEmbedded/fs-updater-lib.git"
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
    libarchive \
    "

RDEPENDS:${PN} = "\
    libubootenv \
    zlib \
    botan \
    libarchive \
    "
EXTRA_OECMAKE += "-DBOTAN2:STRING=${STAGING_DIR_TARGET}/usr/include/botan-2/"
