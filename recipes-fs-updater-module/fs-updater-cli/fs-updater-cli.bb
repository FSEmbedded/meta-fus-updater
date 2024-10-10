# Copyright (C) 2024 F&S Elektronik Systeme GmbH
# Released under the GPLv2 license
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

inherit cmake

SRCREV ?= ""
FSUPCLI_SRC_URI ?= ""
FSUPCLI_GIT_BRANCH ?= "master"

SRC_URI = " \
    ${FSUPCLI_SRC_URI};protocol=https;branch=${FSUPCLI_GIT_BRANCH} \
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
    "
