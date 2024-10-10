SUMMARY = "Copy overlay.ini template to your application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# add dependency to application deployment
# because of binaries
RDEPENDS:${PN} = "application"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "\
	file://overlay.ini \
"
S = "${WORKDIR}"

do_install() {
	install -d ${D}
	# add adu to rootfs because of overlay.ini
	install -d ${D}/adu
}

do_deploy() {
	# copy overlay.ini to deploy dir
	# used by do_create_application_image function
	# to create application image
	cp -rf ${WORKDIR}/overlay.ini ${DEPLOY_DIR_IMAGE}/app
}

addtask deploy after do_install

# list files or directories that are placed in a package
FILES:${PN} += "/adu"
