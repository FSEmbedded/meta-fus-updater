# Copyright (C) 2024 F&S Elektronik Systeme GmbH
# Released under the GPLv2 license
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

inherit cmake pkgconfig
require includes/system_paths.inc

SUMMARY = "Dynamic overlay filesystem mounting for F&S A/B updates"
DESCRIPTION = "Preinit-stage tool that mounts overlay filesystems before \
systemd starts. Handles A/B slot selection, persistent memory detection, \
and optional X.509 certificate store for Azure Device Update."

SRCREV ?= "6a28958875487d8e866258e2826f6d7d99a8ad1c"
DYNOL_SRC_URI ?= "git://github.com/FSEmbedded/dynamic-overlay.git"
DYNOL_GIT_BRANCH ?= "master"

SRC_URI = " \
    ${DYNOL_SRC_URI};protocol=https;branch=${DYNOL_GIT_BRANCH} \
    "

S = "${WORKDIR}/git"
PV = "1.0.0+git${SRCPV}"

FILES:${PN} = " \
	${sbindir}/dynamic_overlay \
"

# Core dependencies (always needed)
DEPENDS += "\
	libubootenv \
	mtd-utils \
	util-linux \
"

RDEPENDS:${PN} += "\
	mtd-utils \
	util-linux \
"

# Override paths that differ from CMake defaults (symlinks on writable overlay)
EXTRA_OECMAKE += " -DLOG_BACKEND=KMSG"
EXTRA_OECMAKE += " -DRAUC_SYSTEM_CONF_PATH=${RAUC_SYSTEM_CONF_PATH}"
EXTRA_OECMAKE += " -DUBOOT_ENV_PATH=${UBOOT_ENV_PATH}"

PACKAGECONFIG ??= ""
