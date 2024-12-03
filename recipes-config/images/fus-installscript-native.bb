DESCRIPTON = "F&S install additional host script"
LICENSE = "MIT"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r0"

SRC_URI = " \
    file://addfsheader.sh \
    "

inherit native

# add other scripts like addfsheader.sh to use it
# in recipes for target build
do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/addfsheader.sh ${D}${bindir}/addfsheader.sh
}

# add other scripts to for deploy process
FILES:${PN} = "${bindir}/addfsheader.sh"
