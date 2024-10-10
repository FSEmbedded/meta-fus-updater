# The udev rules for automatically calling the update mechanism

DESCRIPTION = "udev rule for autoupdate"
RDEPENDS:${PN} = "udev"
LICENSE = "CLOSED"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://99-fus-updater-usb-auto-mount.rules \
		   file://usb_fs_updater.sh \
"
S = "${WORKDIR}"

FILES:${PN} += " /etc/udev/rules.d/99-fus-updater-usb-auto-mount.rules \
				 /usr/libexec/usb_fs_updater.sh \
"

do_install:append(){
	install -d ${D}/etc/udev/rules.d/
	install -d ${D}/usr/libexec/

	install -m 0444 ${S}/99-fus-updater-usb-auto-mount.rules ${D}/etc/udev/rules.d/
	install -m 0444 ${S}/usb_fs_updater.sh ${D}/usr/libexec/

}

