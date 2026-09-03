## Overview FSUP framework images

The image *fus-image-updater-std* extends *fus-image-std* image configuration and creates additional images for FSUP framework.

The framework is based on RAUC and uses the tool to update devices. RAUC update is described by configuration file.

### RAUC artifacts

The framework offers configurations for 2 boot device types:
- NAND - in subdirectory *rauc/rauc_template_nand/manifest.raucm*
- eMMC - in subdirectory *rauc/rauc_template_emmc/manifest.raucm*

> Note: Currently only eMMC boot device is supported.

The binaries can be found in *<build-dir>/tmp/deploy/images/<architecture>/* directory
- for eMMC - *<IMAGE_LINK_NAME>.rauc_update_emmc.artifact*
- for NAND - *<IMAGE_LINK_NAME>.rauc_update_nand.artifact*

> Note: Artifact names are prefixed with the image name (`IMAGE_LINK_NAME`, which
> carries the machine suffix, e.g. `<image>-<machine>`) because several product images
> share the same deploy directory; without the prefix, the last image built would
> silently overwrite the others' artifacts. Unqualified compatibility symlinks (e.g.
> *rauc_update_emmc.artifact*) are also created next to the real files unless
> `FSUP_ARTIFACT_COMPAT = "0"` is set - but such a symlink points at whichever image
> was **deployed last**, not "built last", so scripts that need a specific image's
> artifact must use the per-image name. See `meta-fus-updater/classes/fus-updater-
> defaults.bbclass` for `FSUP_ARTIFACT_PREFIX` and `FSUP_ARTIFACT_COMPAT`.

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