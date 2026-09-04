# Set defaults for fsup framework

# Cert/signing config defaults (CERT_BASE_DIR, FUS_BUILD_VARIANT, FUS_USE_INTERMEDIATE_CERT)
inherit fus-cert-defaults

# Variables for application image creation
APPLICATION_VERSION ?= "20241019"
APPLICATION_CONTAINER_NAME ?= "application_container"
APPLICATION_DEPLOY_DIR ?= "${DEPLOY_DIR_IMAGE}/app"

# Application deployment mode:
#   "container" (default) - app is built as a signed squashfs in the data
#                           partition (app_a/b.squashfs), OTA-updatable on its own.
#   "rootfs"              - app ships inside the rootfs image (no data-partition
#                           container; app updated only via a full firmware/rootfs
#                           update). The framework skips all container/app-OTA
#                           machinery in this mode; a consumer recipe must install
#                           the app payload into the rootfs.
FUS_APPLICATION_DEPLOY_MODE ?= "container"

# Variables for firmware image creation
FIRMWARE_VERSION ?= "20241019"

FS_PROVISIONING_SERVICE_DIR_NAME ?= "fs-provisioning"

FSUP_IMAGE_DIR_NAME ?= "fsup-framework-bin"
FSUP_TEMPLATE_FILE_NAME ?= "fsupdate-template.json"

# set compression method
SQUASHFS_COMPRESSOR ?= "zstd"
# set additional flags, must be suitable to compression method
# used in wic configuration too to set --mkfs-extraopts
SQUASHFS_EXTRA_IMAGECMD ?= "-comp ${SQUASHFS_COMPRESSOR} -Xcompression-level 19"

# Hand the same flags to the stock squashfs image type. The wic path reads
# SQUASHFS_EXTRA_IMAGECMD directly, but a squashfs entry in IMAGE_FSTYPES goes through
# IMAGE_CMD:squashfs, which expands EXTRA_IMAGECMD - unset, so those images silently fell
# back to the default compressor and carried whatever the flags were meant to exclude.
# Type-scoped so it cannot reach the ubifs/ext4/wic commands, and weak so an image or
# machine can still override it.
EXTRA_IMAGECMD:squashfs ?= "${SQUASHFS_EXTRA_IMAGECMD}"

# Update artifacts are named per image and deployed through IMGDEPLOYDIR. They used to be
# written under fixed names straight into the shared deploy directory, so several images
# built into it overwrote each other silently - and because that bypassed sstate, the
# overlap check that exists for exactly this never saw them.
FSUP_ARTIFACT_PREFIX ?= "${IMAGE_LINK_NAME}."

# Keep the historic unqualified names as symlinks. They point at whichever image was
# deployed last, so they mean "installed last", not "built last". Set to "0" to deploy
# only the per-image names.
FSUP_ARTIFACT_COMPAT ?= "1"

# Signing material, resolved here rather than inside the task bodies so the paths can be
# put into the task hashes (see the file-checksums flags in base-fus-updater.bbclass).
FUS_SIGN_SYSTEM_DIR ?= "${CERT_BASE_DIR}/${FUS_BUILD_VARIANT}/system"
FUS_SIGN_APP_DIR ?= "${CERT_BASE_DIR}/${FUS_BUILD_VARIANT}/app"

# The root the application signing cert is checked against. It has its own variable so
# that pointing FUS_SIGN_APP_DIR at another cert store moves the root with it: checking a
# rotated signing cert against a root left behind elsewhere either fails the build for no
# reason or passes on a root that is no longer the one deployed to the device.
FUS_SIGN_APP_ROOT_DIR ?= "${CERT_BASE_DIR}/${FUS_BUILD_VARIANT}/root"
