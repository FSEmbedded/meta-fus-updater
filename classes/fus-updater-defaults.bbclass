# Set defaults for fsup framework

# enviroments to create application image
APPLICATION_VERSION ?="20241019"
APPLICATION_CONTAINER_NAME ?= "application_container"
# enviroments to create firmware image
FIRMWARE_VERSION ?= "20241019"

FS_PROVISIONING_SERVICE_DIR_NAME ?="fs-provisioning"

FSUP_IMAGE_DIR_NAME ?="fsup-framework-bin"
FSUP_TEMPLATE_FILE_NAME ?= "fsupdate-template.json"

# set compression method
SQUASHFS_COMPRESSOR ?= "zstd"
# set addtional flags, must be suitable to compression method
# used in wic configuration too to set --mkfs-extraopts
SQUASHFS_EXTRA_IMAGECMD ?= "-comp ${SQUASHFS_COMPRESSOR} -Xcompression-level 19"

# Sets build variant to prod or dev. Is using to create
# specific certificates to sing rauc buindles or application image.
FUS_BUILD_VARIANT ?= "dev"
# 1 use Intermediate to create sign certificate
# 0 use root to create sign certificate
FUS_USE_INTERMEDIATE_CERT ?= "1"

# enviroment
KERNEL_IMAGE_NAME ?= "zImage"
