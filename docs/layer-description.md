## Description of the meta-fus-updater layer

### classes/base_fus_updater.bbclass:

Extends build process to create specific images for fsup framework.
The creation process is part of do image task and extends them to
create following images
- **do_create_update_package**
  - creates squashfs images of rootfs, persistent-partition,
    application image for eMCC and NAND boot device.
  - creates rauc artifacts
    - *rauc_update_nand.artifact* would be created if ubifs
      image type is defined
    - *rauc_update_emmc.artifact*. would be created if wic.gz or wic
      image type is defined
- **create_update_images** task creates fsupdate images
  for eMMC and NAND in image post process.
  They are three images types:
  - *firmware.fs* is firmware update for fs-updater cli.s
  - *application.fs* is application update for fs-updater cli
  - *common-update.fs* is firmware and application update for fs-updater cli

### conf/layer.conf:

Ensures that the build system uses correct paths and priority to find and
process the recipes and metadata in the layer.
- compatible: kirkstone
- priority: 10

### rauc/*:

Contains the relevant information for the rauc update process.
On stage 1 the certificates and keys and on stage 2 the templates for
NAND and eMMC.
The template for NAND contains also a placeholder for the devie tree file (.dtb), that is set in the variable UBOOT_DTB_NAME.

### recipes-2-stage-boot/*:

To solve the problem of additional .service files during init process.
The overlays are mounted before the init process starts. There is a
***preinit.sh*** created, that mounts and starts the init process.

### recipes-application/*:

Installs the application image inside the data partition.
Place you image below files/ directory

### recipes-auto-usb-update/*:

Install the UDEV-rules for automatic firmware, application or common update
with an usb drive or sd card. The stick or sd card must have the label **FUS-UPDATER**
and a vfat filesystem. The stick contains all files and a **update_config**,
that describes the update file with name and version.

### recipes-dynamic_overlay/*:

Contain the dynamic mounting, which is started inside ***preinit.sh***.

### recipes-fs-updater-module/*:

FS-Update (CLI) for installing firmware, application or common updates.
Place the source distribution generated from the repostory of fs-updater.
Place it below the files/ directory.

### recipes-rauc-core/*:

Adaptions for the rauc update process.

### recipes-u-boot-fw-utils/*:

Add fw_enc.config for nand and eMMC memory

### wic/*:

File to generate sdcard image for eMMC.

### docs/*:

Documentation in markdown format