## Description of the meta-fus-updater layer

### classes/base-fus-updater.bbclass

Extends the build process to create specific images for the FSUP framework.
The images are created during the image tasks:
- the image type **update_package** (`IMAGE_CMD:update_package`)
  - creates the SquashFS image of the rootfs for eMMC and NAND boot devices,
    the UBIFS image of the persistent partition for NAND (on eMMC it is an ext4
    partition from the wks file) and, in container mode, the SquashFS
    application image.
- the **do_create_update_package** task
  - creates RAUC artifacts, named after the image (`<IMAGE_LINK_NAME>.<name>`,
    e.g. `<image>-<machine>.rauc_update_nand.artifact`), with an
    unqualified compatibility symlink kept next to each
    - *rauc_update_nand.artifact* is created if the ubifs
      image type is defined
    - *rauc_update_emmc.artifact* is created if the wic.gz or wic
      image type is defined
- the image postprocess command **create_update_images**
  - creates the fsupdate images
    for eMMC and NAND, also named after the image with
    an unqualified compatibility symlink kept next to each.
    There are three image types, where &lt;dev&gt; is *emmc* or *nand*; with
    `FUS_APPLICATION_DEPLOY_MODE = "rootfs"` only the firmware update is created:
    - *firmware_&lt;dev&gt;.fs* is the firmware update for the fs-updater CLI
    - *application.fs* is the application update for the fs-updater CLI
    - *update_&lt;dev&gt;.fs* is the firmware and application update for the fs-updater CLI

### conf/layer.conf

Ensures that the build system uses the correct paths and priority to find and
process the recipes and metadata in the layer.
- compatible: kirkstone, scarthgap
- priority: 10

### rauc/*

Contains the RAUC manifest templates and install-check hooks for
NAND and eMMC.
The template for NAND also contains a placeholder for the device tree file (.dtb), which is taken from the first entry of KERNEL_DEVICETREE.

### recipes-2-stage-boot/*

Solves the problem of additional .service files during the init process.
The overlays are mounted before the init process starts. A
***preinit.sh*** is created, which mounts them and starts the init process.

### recipes-application/*

Example recipes for the application:
- *application* (in *application-example*) builds a sample application from *files/src* and deploys it
  with *overlay.ini* to *${DEPLOY_DIR_IMAGE}/app*, where **base-fus-updater.bbclass**
  packs it into the application image
- *application-container-native* (in *application-container*) provides the tool that creates the signed
  application package
- *application-config* (in *application-config-example*) provides an *overlay.ini* template

### recipes-auto-usb-update/*

Installs the udev rules for automatic firmware, application or common updates
with a USB drive or SD card. The stick or SD card must have the label **FUS-UPDATER**.
The stick contains all files and an **update_config**,
which describes the update file, see [automatic-update.md](automatic-update.md).

### recipes-dynamic_overlay/*

Contains the dynamic mounting, which is started inside ***preinit.sh***.

### recipes-fs-updater-module/*

fs-updater (CLI) and its library for installing firmware, application or common updates.
Both recipes fetch their sources from git.

### recipes-rauc-core/*

Adaptations for the RAUC update process.
- *rauc_%.bbappend* adds the mark-good service for the FSUP framework

### recipes-bsp/*

Adds fw_env.config for NAND and eMMC memory.

### wic/*

File to generate an SD card image for eMMC.

### docs/*

Documentation in markdown format.
