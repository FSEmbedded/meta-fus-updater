# Set defaults for fsup framework

# Variables for application image creation
APPLICATION_VERSION ?= "20241019"
APPLICATION_CONTAINER_NAME ?= "application_container"
APPLICATION_DEPLOY_DIR ?= "${DEPLOY_DIR_IMAGE}/app"

# Application deployment mode:
#   "container" (default) - app is built as a signed squashfs in the data
#                           partition (app_a/b.squashfs), OTA-updatable.
#   "rootfs"              - app baked into the rootfs image (no data-partition
#                           container; app updated only via full firmware update).
#                           NOTE: not yet implemented (planned).
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

# Sets build variant to prod or dev. Used to create
# specific certificates to sign RAUC bundles or application image.
FUS_BUILD_VARIANT ?= "dev"
# 1 use Intermediate to create sign certificate
# 0 use root to create sign certificate
FUS_USE_INTERMEDIATE_CERT ?= "1"
