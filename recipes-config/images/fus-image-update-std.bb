DESCRIPTION = "F&S standard update image"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit base-fus-updater

FSUP_WKS_FILE ??="fus-updater-sdcard.wks.in"

WKS_FILE = "${FSUP_WKS_FILE}"
IMAGE_FSTYPES:append = " wic update_package"

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
    rauc-updater \
"

TOOLCHAIN_TARGET_TASK:append  = " kernel-devsrc"
TOOLCHAIN_TARGET_TASK:append  = " inicpp inicpp-dev inicpp-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " libubootenv libubootenv-dev libubootenv-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " zlib zlib-dev zlib-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " jsoncpp jsoncpp-dev jsoncpp-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " botan botan-dev botan-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " tclap tclap-dev"
TOOLCHAIN_TARGET_TASK:append  = " fs-updater-lib fs-updater-lib-dev fs-updater-lib-staticdev"
TOOLCHAIN_TARGET_TASK:append  = " util-linux util-linux-dev"

TOOLCHAIN_HOST_TASK:append = " nativesdk-cmake nativesdk-make nativesdk-pkgconfig nativesdk-libtool"

#### Remove following line if you want to remove the sample application ###
CORE_IMAGE_EXTRA_INSTALL += " application"
IMAGE_INSTALL:append = " rauc"

IMAGE_NAME_SUFFIX = "-update"
