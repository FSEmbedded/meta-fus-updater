# Copyright (C) 2024 F&S Elektronik Systeme GmbH
# Released under the GPLv2 license
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

SUMMARY = "FS update Framework library"
SECTION = "libs"

inherit cmake pkgconfig

SRCREV ?= "9ff626055f50f17d51ae008b45742b1620898861"
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
    boost \
    libarchive \
    pkgconfig-native \
    "

EXTRA_OECMAKE += "-Dupdate_version_type=string"
# Ensure headers are in dev package
FILES:${PN}-dev += "${includedir}/fs_update_framework/*"
