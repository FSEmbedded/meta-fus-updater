## Overview FSUP framework images

The image *fus-image-updater-std* extends *fus-image-std* image configuration and creates additional images for FSUP framework.

The framework is based on RAUC and use the tool to update devices. RAUC update is descirbed by configuration file.

### RAUC artifacts

The framework offers configurations for 2 boot device types:
- NAND - in subdirecotry *rauc/rauc_template_nand/manifest.raucm*
- eMMC - in subdirecotry *rauc/rauc_template_emmc/manifest.raucm*

> Note: Currently only eMMC boot device is supported.

The binaries can be found in *<build-dir>/tmp/deploy/images/<architecture>/* directory
- for eMMC - *rauc_update_emmc.artifact*
- for NAND - *rauc_update_nand.artifact*

### FSUP framework update images

FUS CLI supports handling of three update image types *application*,
*firmware* and *common*. The build process creates and copies this images to
*<build-dir>/tmp/deploy/images/<architecture>/fsup-framework-bin* directory.

- firmware_[emmc/nand].fs is an tar.bz2 archive
  - update.fw - RAUC image
  - fsupdate.json - update description
- application_[emmc/nand].fs is an tar.bz2 archive
  - update.app - SquashFS image with all application artifacts
  - fsupdate.json - update description
- update_[emmc/nand].fs - is an tar.bz2 archive
  - update.fw - RAUC image
  - update.app - SquashFS image with all application artifacts
  - fsupdate.json - update description