DESCRIPTION = "F&S standard update image"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FSUP_WKS_FILE ??="fus-updater-sdcard.wks.in"

python(){
    supported_machines = ["fsimx8mm", "fsimx8mp"]
    if d.getVar('MACHINE') not in supported_machines:
        machine = d.getVar("MACHINE")
        bb.fatal(f"The {machine} is not supported/tested for meta-fus-updater layer")
    else:
        wksfile = d.getVar("FSUP_WKS_FILE")
        d.setVar("WKS_FILE", wksfile)
        d.setVar("IMAGE_FSTYPES", "wic update_package")
}

addtask do_create_update_package after do_image_wic before do_image_complete

require recipes-config/images/fus-image-std.bb

CORE_IMAGE_EXTRA_INSTALL += " \
    libubootenv-bin \
    u-boot-fw-config \
    dynamic-overlay \
    fs-updater-cli \
    auto-usb-update \
    2-stage-boot \
    rauc \
"

TOOLCHAIN_TARGET_TASK:append  = " kernel-devsrc"
TOOLCHAIN_TARGET_TASK:append  = " inicpp inicpp-dev inicpp-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " libubootenv libubootenv-dev libubootenv-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " zlib zlib-dev zlib-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " jsoncpp jsoncpp-dev jsoncpp-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " botan botan-dev botan-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " tclap tclap-dev"
TOOLCHAIN_TARGET_TASK:append  = " fs-updater-lib fs-updater-lib-dev fs-updater-lib-staticdev"

TOOLCHAIN_HOST_TASK:append = " nativesdk-cmake nativesdk-make"

#### Remove following line if you want to remove the sample application ###
CORE_IMAGE_EXTRA_INSTALL += " application"
IMAGE_INSTALL:append = " rauc"
