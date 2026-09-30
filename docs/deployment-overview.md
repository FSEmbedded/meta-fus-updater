## Overview FSUP framework images

The image *fus-image-update-std* extends the *fus-image-std* image configuration and creates additional images for the FSUP framework.

The framework is based on RAUC and uses it to update devices. A RAUC update is described by a configuration file.

### RAUC artifacts

The framework offers configurations for two boot device types:
- NAND - in subdirectory *rauc/rauc_template_nand/manifest.raucm*
- eMMC - in subdirectory *rauc/rauc_template_mmc/manifest.raucm*

> Note: Currently only eMMC boot device is supported.

The binaries can be found in the *&lt;build-dir&gt;/tmp/deploy/images/&lt;architecture&gt;/* directory:
- for eMMC - *&lt;IMAGE_LINK_NAME&gt;.rauc_update_emmc.artifact*
- for NAND - *&lt;IMAGE_LINK_NAME&gt;.rauc_update_nand.artifact*

> Note: Artifact names are prefixed with the image name (`IMAGE_LINK_NAME`, which
> carries the machine suffix, e.g. `<image>-<machine>`) because several product images
> share the same deploy directory; without the prefix, the last image built would
> silently overwrite the others' artifacts. Unqualified compatibility symlinks (e.g.
> *rauc_update_emmc.artifact*) are also created next to the real files unless
> `FSUP_ARTIFACT_COMPAT = "0"` is set - but such a symlink points at whichever image
> was **deployed last**, not "built last", so scripts that need a specific image's
> artifact must use the per-image name. See
> `meta-fus-updater/classes/fus-updater-defaults.bbclass` for `FSUP_ARTIFACT_PREFIX`
> and `FSUP_ARTIFACT_COMPAT`.

### FSUP framework update images

The fs-updater CLI supports three update image types: *application*,
*firmware* and *common*. The build process creates these images and copies them to the
*&lt;build-dir&gt;/tmp/deploy/images/&lt;architecture&gt;/fsup-framework-bin* directory, where `<dev>` is `emmc` or `nand`.

- `firmware_<dev>.fs` is a tar.bz2 archive
  - update.fw - RAUC image
  - fsupdate.json - update description
- `application.fs` is a tar.bz2 archive
  - update.app - SquashFS image with all application artifacts
  - fsupdate.json - update description
- `update_<dev>.fs` is a tar.bz2 archive
  - update.fw - RAUC image
  - update.app - SquashFS image with all application artifacts
  - fsupdate.json - update description
