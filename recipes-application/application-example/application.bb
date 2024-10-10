# Copyright (C) 2024 F&S Elektronik Systeme GmbH
LICENSE = "CLOSED"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "\
    file://src \
    file://overlay.ini \
    file://systemd-application-generator \
    "

S="${WORKDIR}/src"

# systemd is required to use service for application start
REQUIRED_DISTRO_FEATURES = "systemd"
# add cmake for build process of application
inherit cmake features_check

do_install() {
    local appdir=${WORKDIR}/app
    install -d ${D}
    # add adu to rootfs because of overlay.ini
    install -d ${D}/adu
    # add app directory to workdir
    # use the folder to copy all application data
    # to create application image
    install -d ${appdir}
    install -d ${appdir}/etc
    install -d ${appdir}/usr/bin
    install ${B}/app_sample ${appdir}/usr/bin
    install -d ${appdir}/${systemd_system_unitdir}
    install -m 0644 ${S}/start_application.service ${appdir}/${systemd_system_unitdir}
    # the generator enable application start service
    install -d ${appdir}/${systemd_unitdir}/system-generators/
    install -m 0755 ${WORKDIR}/systemd-application-generator ${appdir}/${systemd_unitdir}/system-generators/
}

do_deploy() {
    local appdir=${WORKDIR}/app
    rm -rf ${DEPLOY_DIR_IMAGE}/app
    mkdir -p ${DEPLOY_DIR_IMAGE}/app
    cp -rf ${appdir}/* ${DEPLOY_DIR_IMAGE}/app
    cp -rf ${WORKDIR}/overlay.ini ${DEPLOY_DIR_IMAGE}/app
}

addtask deploy after do_install

fsup_app_clean() {
    # remove app directory from deploy folder
    rm -rf ${DEPLOY_DIR_IMAGE}/app
}

# extend do_clean function to remove all available manifest files
do_clean:append() {
    # call fsup_app_clean function
    bb.build.exec_func('fsup_app_clean', d)
}

PACKAGES += "${PN}-application"
# list files or directories that are placed in a package
FILES:${PN} += "\
    /adu \
    "
