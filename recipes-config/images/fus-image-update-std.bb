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

require recipes-config/images/fus-image-std.bb

DESCRIPTION = "F&S standard update image based on X11 and matchbox"
LICENSE = "MIT"
FIRMWARE_VERSION ?= "20210304"

CORE_IMAGE_EXTRA_INSTALL += " \
	u-boot-fw-utils \
	dynamic-overlay \
	auto-usb-update \
	2-stage-boot \
	application \
	rauc \
"
