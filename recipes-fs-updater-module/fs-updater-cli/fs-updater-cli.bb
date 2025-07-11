# Copyright (C) 2024 F&S Elektronik Systeme GmbH
# Released under the GPLv2 license
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRCREV ?= "fad55a20dcf9744a24d58bd0f3acee45cb6d616b"
FSUPCLI_SRC_URI ?= "git://github.com/FSEmbedded/fs-updater-cli.git"
FSUPCLI_GIT_BRANCH ?= "master"

SRC_URI = " \
    ${FSUPCLI_SRC_URI};protocol=https;branch=${FSUPCLI_GIT_BRANCH} \
    file://fsup-framework-cli \
"

S = "${WORKDIR}/git"
PV = "+git${SRCPV}"

inherit cmake pkgconfig

DEPENDS = " \
    libubootenv \
    botan \
    jsoncpp \
    zlib \
    boost \
    fs-updater-lib \
    tclap \
    libarchive \
    bash-completion \
    pkgconfig-native \
"

EXTRA_OECMAKE += "-Dupdate_version_type=string"

do_install:append() {
    # install bash completion script for fs-updater parameter
    install -D -m 0644 ${WORKDIR}/fsup-framework-cli ${D}${sysconfdir}/bash_completion.d/fs_updater
}
