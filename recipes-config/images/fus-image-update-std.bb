python(){
    if "fsimx8mm" == d.getVar("MACHINE"):
        d.setVar("WKS_FILE", "fus-updater-sdcard.wks.in")
        d.appendVar("IMAGE_FSTYPES", " wic")
    else:
        machine = d.getVar("MACHINE")
        bb.fatal(f"The {machine} is not supported/tested for meta-fus-updater layer")
}

addtask do_create_update_package after do_image_wic before do_image_complete

IMAGE_FSTYPES_append = " update_package"
DESCRIPTION = "F&S standard update image based on X11 and matchbox"
LICENSE = "MIT"

require recipes-config/images/fus-image-std.bb


CORE_IMAGE_EXTRA_INSTALL += " \
	u-boot-fw-utils \
	dynamic-overlay \
	python3-fs-updater-lib \
	python3-fs-updater-cli \
	fs-updater-cli \
	auto-usb-update \
	2-stage-boot \
	rauc \
"

TOOLCHAIN_TARGET_TASK_append  = " kernel-devsrc"
TOOLCHAIN_TARGET_TASK_append  = " inicpp inicpp-dev inicpp-staticdev"
TOOLCHAIN_TARGET_TASK_append  = " libubootenv libubootenv-dev libubootenv-staticdev"
TOOLCHAIN_TARGET_TASK_append  = " zlib zlib-dev zlib-staticdev"
TOOLCHAIN_TARGET_TASK_append  = " jsoncpp jsoncpp-dev jsoncpp-staticdev"
TOOLCHAIN_TARGET_TASK_append  = " botan botan-dev botan-staticdev"
TOOLCHAIN_TARGET_TASK_append  = " tclap tclap-dev"
TOOLCHAIN_TARGET_TASK_append  = " fs-updater-lib fs-updater-lib-dev fs-updater-lib-staticdev"

TOOLCHAIN_HOST_TASK_append = " nativesdk-cmake nativesdk-make"


#### Remove following line if you want to remove the sample application ###
CORE_IMAGE_EXTRA_INSTALL += "\
	application \
	application-config \
"
