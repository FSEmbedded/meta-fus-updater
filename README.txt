Description of the meta-fus-updater layer:
-------------------------------------------------------------------------------

* classes/base_fus_updater.bbclass:

Describes two tasks: One to create the nand versions of rootfs and
persistent-partition and antother to create the
rauc_update_(nand/emmc).artifact. The processes are starte after the creation
of the rootfs.

* conf/layer.conf:

Install all packages to the device.

* conf/machine/fsimx8mm-extra.conf:

Extends the standard configuration of teh fsimx8mm of the machine description.
It extends the default IMAGES_FSTYPES string with own targets. Also it set a
new wks.in file for creating a emmc image.

* rauc/*:

Contains the relevant infomration for the rauc update process.
On stage 1 the certificates and keys and on stage 2 the templates for
NAND and eMMC.
The template for NAND contains also a placholder for the devie tree file
(.dtb) that is set in the variable UBOOT_DTB_NAME.

* recipes-2-stage-boot/*:

To solve the problem of additional .service files during init process.
The overlays are mounted before the init process starts. There is a
preinit.sh created, that mounts and starts the init process.

* recipes-application/*:

Installs the application image inside the data partition.
Place you image below files/ directory

* recipes-auto-usb-update/*:

Install the UDEV-rules for automatic firmware and application update with
an usb drive or sd card. The stick or sd card must have the label FUS-UPDATER
and a vfat filesystem. The stick conatins all files and a "update_config", that
describes the update file with name and version.

* recipes-auto-usb-update/*:

Contain the dynamic mounting, which is started inside preinit.sh

* recipes-fs-updater-module/*:

FS-Update (CLI) for installing firmware updates and application updates.
Place the source distribution generated from the repostory of fs-updater.
Place it below the files/ directory.

* recipes-rauc-core/*:

Adaptions for the rauc application update process.

* recipes-u-boot-fw-utils/*:

Add fw_enc.config for nand and eMMC memory

* wic/*:

File to generate sdcard image for eMMC.


