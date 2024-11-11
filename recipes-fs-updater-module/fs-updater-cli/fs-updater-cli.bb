# Copyright (C) 2024 F&S Elektronik Systeme GmbH
# Released under the GPLv2 license
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "\
    file://src \
    file://overlay.ini \
    file://systemd-application-generator \
    "

inherit cmake

SRCREV ?= "25ad75109dba46d54dc9e2a20c8001df827e712c"
FSUPCLI_SRC_URI ?= "git://github.com/FSEmbedded/fs-updater-cli.git"
FSUPCLI_GIT_BRANCH ?= "master"

SRC_URI = " \
    ${FSUPCLI_SRC_URI};protocol=https;branch=${FSUPCLI_GIT_BRANCH} \
    file://fsup-framework-cli \
    "

S = "${WORKDIR}/git"
PV = "+git${SRCPV}"

DEPENDS = " \
    libubootenv \
    botan \
    jsoncpp \
    zlib \
    inicpp \
    fs-updater-lib \
    tclap \
    libarchive \
    "
# add bash-completion to use own
# completion script
DEPENDS +="bash-completion"

do_install:append() {
    # install bash completion script for fs-updater parameter
    install -D -m 0644 ${WORKDIR}/fsup-framework-cli ${D}${sysconfdir}/bash_completion.d/fs_updater
}
