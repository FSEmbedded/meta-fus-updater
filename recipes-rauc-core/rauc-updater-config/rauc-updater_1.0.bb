SUMMARY = "RAUC and fw_env.conf Configuration Updater"
DESCRIPTION = "Updates RAUC system.conf and fw_env.conf to match the current boot device"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://rauc-updater-config.sh \
    file://rauc-updater-config.service \
"

inherit systemd

SYSTEMD_SERVICE:${PN} = "rauc-updater-config.service"
SYSTEMD_AUTO_ENABLE:{PN} = "enable"
RDEPENDS:${PN} += "bash"

# Dependency on U-Boot, RAUC and basic system tools
RDEPENDS:${PN} += "u-boot-fw-utils rauc coreutils"

do_install() {
    install -d ${D}${sbindir}
    install -d ${D}${systemd_system_unitdir}

    install -m 0755 ${WORKDIR}/rauc-updater-config.sh ${D}${sbindir}/rauc-updater-config.sh
    install -m 0644 ${WORKDIR}/rauc-updater-config.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${sbindir}/rauc-updater-config.sh"
FILES:${PN} += "${systemd_system_unitdir}/rauc-updater-config.service"
