DESCRIPTION = "Crate application and copy it to data partition"
LICENSE = "CLOSED"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "\
	file://application \
"

S = "${WORKDIR}"

RDEPENDS_${PM} += "squashfs-tools-native"

FILES_${PN} = "rw_fs/root/application/app_a.squashfs \
			   rw_fs/root/application/app_b.squashfs \
			   rw_fs/root/application/current \
			  "


do_install() {
	install -d ${D}/rw_fs/root/application/current
	install -m  0775 ${WORKDIR}/application ${D}/rw_fs/root/application/app_a.squashfs
	install -m  0775 ${WORKDIR}/application ${D}/rw_fs/root/application/app_b.squashfs
}
