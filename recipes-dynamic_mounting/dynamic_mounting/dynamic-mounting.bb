DESCRIPTION = "Script for mounting applications during boot"
RDEPENDS_${PN} = "python3-core"
LICENSE = "CLOSED"

FILESEXTRAPATHS_prepend := "${THISDIR}:"


SRC_URI = "file://dynamic_mounting.py"
S = "${WORKDIR}/"

FILES_${PN} = "rw_fs/dynamic_mounting.py \
			   rw_fs/root/application/current \
"

do_install() {
	install -d  ${D}/rw_fs/root/application/current
	install -m 0555 ${S}/dynamic_mounting.py ${D}/rw_fs/
}

