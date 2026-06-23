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
