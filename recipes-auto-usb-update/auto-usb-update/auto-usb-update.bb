SUMMARY = "FUS USB Update helper"
DESCRIPTION = "Udev rule, systemd unit and updater wrapper for USB updates"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

S = "${WORKDIR}"

SRC_URI = " \
    file://99-fus-updater.rules \
    file://fus-usb-update@.service \
    file://usb_fs_updater.sh \
"

inherit systemd allarch

RDEPENDS:${PN} += "udev systemd busybox fs-updater-cli"

SYSTEMD_SERVICE:${PN} = "fus-usb-update@.service"
# Template units must not be auto-enabled
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

do_install() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -d ${D}${systemd_system_unitdir}
    install -d ${D}${libexecdir}

    install -m0644 ${WORKDIR}/99-fus-updater.rules  ${D}${sysconfdir}/udev/rules.d/
    install -m0644 ${WORKDIR}/fus-usb-update@.service ${D}${systemd_system_unitdir}/
    install -m0755 ${WORKDIR}/usb_fs_updater.sh      ${D}${libexecdir}/
}