# Copyright (C) 2024 F&S Elektronik Systeme GmbH
SUMMARY = "Example application for F&S update framework"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "\
    file://src \
    file://overlay.ini \
    file://systemd-application-generator \
    "

S = "${WORKDIR}/src"

# systemd is required to use service for application start
REQUIRED_DISTRO_FEATURES = "systemd"
# add cmake for build process of application
inherit cmake features_check

# Bundle directory (inside WORKDIR)
APP_BUNDLE_DIR = "${WORKDIR}/app"

do_install() {
    local appdir=${APP_BUNDLE_DIR}
    # add app directory to workdir
    # use the folder to copy all application data
    # to create application image
    install -d ${appdir}
    install -d ${appdir}/etc
    install -d ${appdir}/usr/local/bin
    install ${B}/app_sample ${appdir}/usr/local/bin
    install -d ${appdir}/${systemd_system_unitdir}
    install -m 0644 ${S}/start_application.service ${appdir}/${systemd_system_unitdir}
    # the generator enable application start service
    install -d ${appdir}/${systemd_unitdir}/system-generators/
    install -m 0755 ${WORKDIR}/systemd-application-generator ${appdir}/${systemd_unitdir}/system-generators/
    # install to rootfs
    install -d ${D}/usr/local/bin
}

do_deploy() {
    local appdir=${APP_BUNDLE_DIR}
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


ALLOW_EMPTY:${PN} = "1"
FILES:${PN} = "/usr/local/bin"
