# F&S base functions to create update images

# enviroments to create application image
APPLICATION_VERSION ?="20241019"
APPLICATION_CONTAINER_NAME ?= "application_container"
# enviroments to create firmware image
FIRMWARE_VERSION ?= "20241019"

FS_PROVISIONING_SERVICE_DIR_NAME ?="fs-provisioning"

FSUP_IMAGE_DIR_NAME ?="fsup-framework-bin"
FSUP_TEMPLATE_FILE_NAME ?= "fsupdate-template.json"

# install host scripts for the build process
DEPENDS = " \
    fus-installscript-native \
"

remove_fw_env_config() {
    rm -f ${IMAGE_ROOTFS}/etc/fw_env.config
}

do_create_application_image() {
    local IMAGE_ROOTFS_FUS_UPDATER_BASE=${IMAGE_ROOTFS}/..
    rm -rf ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/app_image
    mkdir -p ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/app_image
    local IMAGE_APP_FUS_UPDATER=${IMAGE_ROOTFS_FUS_UPDATER_BASE}/app_image

    if [ -d ${DEPLOY_DIR_IMAGE}/app ]; then
        cp -a ${DEPLOY_DIR_IMAGE}/app/* ${IMAGE_APP_FUS_UPDATER}
    fi

    # Create application image
    local OUTPUT_IMAGE_NAME=${DEPLOY_DIR_IMAGE}/${APPLICATION_CONTAINER_NAME}
    local APP_KEY=${LAYER_BASE_DIR}/rauc/rauc.key.pem
    local APPLICATION_ROOT_FOLDER=${IMAGE_APP_FUS_UPDATER}
    local APPLICATION_IMAGE=${OUTPUT_IMAGE_NAME}_img
    local app_version=${APPLICATION_VERSION}

    ${STAGING_DIR_NATIVE}/usr/bin/package_app -o ${OUTPUT_IMAGE_NAME} -rf ${APPLICATION_ROOT_FOLDER} -ptm ${STAGING_DIR_NATIVE}/usr/sbin/mksquashfs -v ${app_version} -kf ${APP_KEY}

    # Copy image into data partition
    cp -a ${APPLICATION_IMAGE} ${IMAGE_ROOTFS}/rw_fs/root/application/app_a.squashfs
    cp -a ${APPLICATION_IMAGE} ${IMAGE_ROOTFS}/rw_fs/root/application/app_b.squashfs
    cp -a ${IMAGE_ROOTFS}/rw_fs/root ${IMAGE_DATA_PARTITION_FUS_UPDATER}
    mkdir -p ${IMAGE_ROOTFS}/adu
}

do_create_squashfs_rootfs_images() {

    local IMAGE_ROOTFS_FUS_UPDATER_BASE=${IMAGE_ROOTFS}/..

    rm -rf ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/rootfs_temp
    rm -rf ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/data_partition

    mkdir -p ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/rootfs_temp
    mkdir -p ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/data_partition

    local IMAGE_DATA_PARTITION_FUS_UPDATER=${IMAGE_ROOTFS_FUS_UPDATER_BASE}/data_partition
    local IMAGE_ROOTFS_FUS_UPDATER=${IMAGE_ROOTFS_FUS_UPDATER_BASE}/rootfs_temp

    mkdir -p ${IMAGE_ROOTFS}/rw_fs/root/application/current
    cp -a ${IMAGE_ROOTFS}/* ${IMAGE_ROOTFS_FUS_UPDATER}

    rm -rf ${IMAGE_ROOTFS_FUS_UPDATER}/app

    do_create_application_image

    cp -a ${IMAGE_ROOTFS}/rw_fs/root/* ${IMAGE_DATA_PARTITION_FUS_UPDATER}

    # create fsupdate images for nand boot device
    if [[ "${IMAGE_FSTYPES}" == *"ubifs"* ]]; then
        # Create data partition - nand
        ${STAGING_DIR_NATIVE}/usr/sbin/mkfs.ubifs -r ${IMAGE_DATA_PARTITION_FUS_UPDATER} \
            -o ${IMGDEPLOYDIR}/${IMAGE_NAME}.data-partition-nand.ubifs ${MKUBIFS_ARGS}
        ln -sf ${IMGDEPLOYDIR}/${IMAGE_NAME}.data-partition-nand.ubifs ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.data-partition-nand.ubifs
    fi

    # create fsupdate images for emmc boot device
    if [[ "${IMAGE_FSTYPES}" =~ wic.gz|wic ]]; then
        # Create system partition - nand|emmc
        ${STAGING_DIR_NATIVE}/usr/sbin/mksquashfs ${IMAGE_ROOTFS_FUS_UPDATER} \
            ${IMGDEPLOYDIR}/${IMAGE_NAME}.squashfs ${EXTRA_IMAGECMD} -noappend -comp xz
        ln -sf ${IMGDEPLOYDIR}/${IMAGE_NAME}.squashfs ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.squashfs
    fi
}

# called by addtask in fus-image-update-std
python do_create_update_package() {
    d.setVar("RAUC_BINARY", d.getVar("DEPLOY_DIR_IMAGE"))
    d.appendVar("RAUC_BINARY", "/")
    d.appendVar("RAUC_BINARY", d.getVar("RAUC_BINARY_NAME"))

    d.setVar("RAUC_IMG_WIC", d.getVar("IMGDEPLOYDIR"))
    d.appendVar("RAUC_IMG_WIC", "/")
    d.appendVar("RAUC_IMG_WIC", d.getVar("IMAGE_NAME") + ".rootfs.wic")

    d.setVar("RAUC_IMG_ROOTFS", d.getVar("IMGDEPLOYDIR"))
    d.appendVar("RAUC_IMG_ROOTFS", "/")
    d.appendVar("RAUC_IMG_ROOTFS", d.getVar("IMAGE_NAME") + ".squashfs")

    d.setVar("RAUC_IMG_KERNEL", d.getVar("DEPLOY_DIR_IMAGE"))
    d.appendVar("RAUC_IMG_KERNEL", "/Image")

    d.setVar("RAUC_IMG_DEVICE_TREE", d.getVar("DEPLOY_DIR_IMAGE"))

    d.appendVar("RAUC_IMG_DEVICE_TREE", "/" + d.getVar("KERNEL_DEVICETREE").split(" ")[0].split("/")[-1] )

    d.setVar("RAUC_BINARY", d.getVar("DEPLOY_DIR_TOOLS"))
    d.appendVar("RAUC_BINARY", "/rauc")

    d.setVar("RAUC_CERT", d.getVar("LAYER_BASE_DIR"))
    d.appendVar("RAUC_CERT", "/rauc/rauc.cert.pem")

    d.setVar("RAUC_KEY", d.getVar("LAYER_BASE_DIR"))
    d.appendVar("RAUC_KEY", "/rauc/rauc.key.pem")

    image_fstypes = d.getVar('IMAGE_FSTYPES')

    if 'ubifs' in image_fstypes:
        d.setVar("RAUC_TEMPLATE_NAND", d.getVar("LAYER_BASE_DIR"))
        d.appendVar("RAUC_TEMPLATE_NAND", "/rauc")
        d.appendVar("RAUC_TEMPLATE_NAND", "/rauc_template_nand")
        create_rauc_update_nand(d)

    if 'wic.gz' in image_fstypes or 'wic' in image_fstypes:
        d.setVar("RAUC_TEMPLATE_EMMC", d.getVar("LAYER_BASE_DIR"))
        d.appendVar("RAUC_TEMPLATE_EMMC", "/rauc")
        d.appendVar("RAUC_TEMPLATE_EMMC", "/rauc_template_mmc")
        create_rauc_update_mmc(d)
}

def create_rauc_update_mmc(d):
    import subprocess as sp
    import parted, shutil, pathlib
    # create directory as unsorted, indexed collection
    identify_partition_by_position = dict()
    ###################################
    # Here youc can adapt the partition layout
    # identify_partition_by_position["1"] = "uboot.img"
    # identify_partition_by_position["5"] = "boot.vfat"
    identify_partition_by_position["1"] = "boot.vfat"

    ##################################

    try:
        d.getVar("RAUC_BINARY")
    except:
        bb.fatal("Variable RAUC_BINARY is not defined")

    try:
        d.getVar("RAUC_CERT")

    except:
        bb.fatal("Variable RAUC_CERT not defined")

    try:
        d.getVar("RAUC_KEY")

    except:
        bb.fatal("Variable RAUC_KEY not defined")

    try:
        d.getVar("RAUC_IMG_WIC")

    except:
        bb.fatal("Variable RAUC_IMG_WIC not defined")

    try:
        d.getVar("RAUC_TEMPLATE_EMMC")

    except:
        bb.fatal("Variable RAUC_TEMPLATE_EMMC not defined")


    def dd(input_file: str, output_file: str, count: int, skip: int, bs: int):
        handle = sp.Popen(f"dd if={input_file} of={output_file} count={count} bs={bs} skip={skip}", shell=True, stderr=sp.PIPE)
        handle.wait()
        if handle.returncode != 0:
            error_msg = handle.stderr.read().decode("ASCII").rstrip()
            command = f"dd if={input_file} of={output_file} count={count} bs={bs} skip={skip}"
            bb.fatal(f"Error in dd: {error_msg} \n command: {command}")


    device = d.getVar("RAUC_IMG_WIC")

    device = parted.getDevice(device)
    disk = parted.newDisk(device)
    block_size = device.sectorSize

    dest_dir_mmc = os.path.join(d.getVar("DEPLOY_DIR_IMAGE"), "rauc_update_mmc")

    if os.path.exists(dest_dir_mmc):
        shutil.rmtree(dest_dir_mmc)

    pathlib.Path(dest_dir_mmc).mkdir(parents=True, exist_ok=True)

    path_to_rauc     = d.getVar("RAUC_BINARY")
    path_to_cert     = d.getVar("RAUC_CERT")
    path_to_key      = d.getVar("RAUC_KEY")
    input_dir_mmc    = os.path.join(d.getVar("RAUC_TEMPLATE_EMMC"), "*")

    # Here handle for mmc memory

    handle = sp.Popen(f"cp -r {input_dir_mmc} {dest_dir_mmc}", shell=True, stderr=sp.PIPE)
    handle.wait()
    if handle.returncode != 0:
        error_msg = handle.stderr.read().decode("ASCII").rstrip()
        bb.fatal(f"The copy from {input_dir_mmc} to {dest_dir_mmc} are not successfull: \n {error_msg}")

    for partiton in disk.partitions:

        if str(partiton.number) in identify_partition_by_position.keys():
            count_blocks = partiton.getLength(unit='sectors')
            skip = partiton.geometry.start
            dd(input_file=d.getVar("RAUC_IMG_WIC"),
                output_file=os.path.join(dest_dir_mmc, identify_partition_by_position[str(partiton.number)]),
                count=count_blocks,
                skip=skip,
                bs=block_size)

    shutil.copyfile(d.getVar("RAUC_IMG_ROOTFS"), os.path.join(dest_dir_mmc, "rootfs.squashfs"))

    input_dir_mmc = dest_dir_mmc
    output_file_mmc = os.path.join(d.getVar("DEPLOY_DIR_IMAGE"), "rauc_update_emmc.artifact")

    if os.path.exists(output_file_mmc):
        os.remove(output_file_mmc)


    handle = sp.Popen(f"{path_to_rauc} bundle --key {path_to_key} --cert {path_to_cert} {input_dir_mmc} {output_file_mmc}", shell=True, stderr=sp.PIPE)
    handle.wait()
    if handle.returncode != 0:
        error_msg = handle.stderr.read().decode("ASCII").rstrip()
        command = f"{path_to_rauc} bundle --key {path_to_key} --cert {path_to_cert} {input_dir_mmc} {output_file_mmc}"
        bb.fatal(f"Error in creating RAUC update package for eMMC: \n {error_msg} \n command {command}")

    shutil.rmtree(input_dir_mmc)



def create_rauc_update_nand(d):
    import subprocess as sp
    import shutil, pathlib

    try:
        d.getVar("RAUC_BINARY")
    except:
        bb.fatal("Variable RAUC_BINARY is not defined")

    try:
        d.getVar("RAUC_CERT")

    except:
        bb.fatal("Variable RAUC_CERT not defined")

    try:
        d.getVar("RAUC_KEY")

    except:
        bb.fatal("Variable RAUC_KEY not defined")

    try:
        d.getVar("RAUC_TEMPLATE_NAND")

    except:
        bb.fatal("Variable RAUC_TEMPLATE_NAND not defined")

    dest_dir_nand = os.path.join(d.getVar("DEPLOY_DIR_IMAGE"), "rauc_update_nand")

    if os.path.exists(dest_dir_nand):
        shutil.rmtree(dest_dir_nand)

    pathlib.Path(dest_dir_nand).mkdir(parents=True, exist_ok=True)

    path_to_rauc     = d.getVar("RAUC_BINARY")
    path_to_cert     = d.getVar("RAUC_CERT")
    path_to_key      = d.getVar("RAUC_KEY")

    input_dir_nand   = os.path.join(d.getVar("RAUC_TEMPLATE_NAND"), "*")

    handle = sp.Popen(f"cp -r {input_dir_nand} {dest_dir_nand}", shell=True, stderr=sp.PIPE)
    handle.wait()
    if handle.returncode != 0:
        error_msg = handle.stderr.read().decode("ASCII").rstrip()
        bb.fatal(f"The copy from {input_dir_nand} to {dest_dir_nand} are not successfull: \n {error_msg}")

    input_dir_nand = dest_dir_nand

    shutil.copyfile(d.getVar("RAUC_IMG_ROOTFS"), input_dir_nand + "/rootfs.squashfs")
    shutil.copyfile(d.getVar("RAUC_IMG_DEVICE_TREE"), input_dir_nand + "/" + d.getVar("KERNEL_DEVICETREE").split(" ")[0].split("/")[1] + ".img")
    shutil.copyfile(d.getVar("RAUC_IMG_KERNEL"), input_dir_nand + "/Image.img")

    with open(input_dir_nand + "/install-check", "r+") as file:
        filedata = file.read().replace("${fdt_img}", d.getVar("KERNEL_DEVICETREE").split(" ")[0].split("/")[1] + ".img")
        file.seek(0)
        file.write(filedata)

    with open(input_dir_nand + "/manifest.raucm", "r+") as file:
        filedata = file.read().replace("${fdt_img}", d.getVar("KERNEL_DEVICETREE").split(" ")[0].split("/")[1] + ".img")
        file.seek(0)
        file.write(filedata)

    output_file_nand = os.path.join(d.getVar("DEPLOY_DIR_IMAGE"), "rauc_update_nand.artifact")
    try:
        os.remove(output_file_nand)
    except:
        pass

    handle = sp.Popen(f"{path_to_rauc} bundle --key {path_to_key} --cert {path_to_cert} {input_dir_nand} {output_file_nand}", shell=True, stderr=sp.PIPE)
    handle.wait()
    if handle.returncode != 0:
        error_msg = handle.stderr.read().decode("ASCII").rstrip()
        command = f"{path_to_rauc} bundle --key {path_to_key} --cert {path_to_cert} {input_dir_nand} {output_file_nand}"
        bb.fatal(f"Error in creating RAUC update package for NAND: \n {error_msg} \n command {command}")

    shutil.rmtree(input_dir_nand)

IMAGE_CMD:update_package () {
    do_create_squashfs_rootfs_images
}

create_fsupdate () {
    local update_description_file=fsupdate-common.json
    local prov_service_dir_name="${FS_PROVISIONING_SERVICE_DIR_NAME}"
    local fsup_image_dir_name="${FSUP_IMAGE_DIR_NAME}"
    local fsup_images_dir=${DEPLOY_DIR_IMAGE}/${fsup_image_dir_name}
    local fsup_images_work_dir=${fsup_images_dir}/.work
    local prov_service_home=${DEPLOY_DIR_IMAGE}/${prov_service_dir_name}
    local update_desc_file=${fsup_images_work_dir}/${update_description_file}

    if [ "$1" = "common" ] || [ "$2" = "common" ]; then
        bbwarn "value common for first or second argument is not allowed."
        return 0
    fi

    args="$1 $2"

    for fsupdate_type in $args
    do
        case $fsupdate_type in
        app)
            UPDATE_FILE_NAME=${APPLICATION_CONTAINER_NAME}
            TARGET_UPDATE_SUFFIX="app"
            update_version=${APPLICATION_VERSION}
            update_handler="fus\/application"
            remove_block=6,14d
            target_archiv_name="application"
        ;;
        fw)
            UPDATE_FILE_NAME="rauc_update_${4}.artifact"
            TARGET_UPDATE_SUFFIX="fw"
            update_version=${FIRMWARE_VERSION}
            update_handler="fus\/firwmware"
            remove_block=14,22d
            target_archiv_name="firmware_${4}"
        ;;
        *)
            bbwarn "unknown parameter"
            return 1
        esac

        target=update.${TARGET_UPDATE_SUFFIX}

        # create binaries directory with update images
        mkdir -p ${fsup_images_work_dir}
        # create update
        cp -f ${DEPLOY_DIR_IMAGE}/${UPDATE_FILE_NAME} ${fsup_images_work_dir}/${target}
        # calculate sha256 sum
        update_sha256sum=$(sha256sum ${fsup_images_work_dir}/${target} | cut -f1 -d' ')

        if [ ! -f "${update_desc_file}" ]; then
            # copy fsupdate-template.json
            cp -f ${DEPLOY_DIR_IMAGE}/fsupdate-template.json ${update_desc_file}
        fi
        #
        sed -i "s|<${TARGET_UPDATE_SUFFIX}_update_description>|\"FUS Firmware Update\"|g" "${update_desc_file}"
        sed -i "s|<${TARGET_UPDATE_SUFFIX}_version>|\"${update_version}\"|g" "${update_desc_file}"
        sed -i "s|<${TARGET_UPDATE_SUFFIX}_handler>|\"${update_handler}\"|g" "${update_desc_file}"
        sed -i "s|<${TARGET_UPDATE_SUFFIX}_sha_hash>|\"${update_sha256sum}\"|g" "${update_desc_file}"

        cp -f ${update_desc_file} ${fsup_images_work_dir}/fsupdate.json

        # remove firmware/application update block
        sed -i "$remove_block" ${fsup_images_work_dir}/fsupdate.json

        cd ${fsup_images_work_dir}
        tar cfvj ${target_archiv_name}.tar.bz2 fsupdate.json $target
        # use addfsheader script from native package
        addfsheader.sh -t CERT ${fsup_images_work_dir}/${target_archiv_name}.tar.bz2 > \
            ${fsup_images_dir}/${target_archiv_name}.fs
        rm -f ${fsup_images_work_dir}/fsupdate.json
    done

    if [ "$3" = "common" ]; then
        # check param 3 for combinded update
        cp -f ${update_desc_file} ${fsup_images_work_dir}/fsupdate.json
        cd ${fsup_images_work_dir}
        tar cfvj update_${4}.tar.bz2 fsupdate.json update.app update.fw
        # use addfsheader script from native package
        addfsheader.sh -t CERT ${fsup_images_work_dir}/update_${4}.tar.bz2 > \
            ${fsup_images_dir}/update_${4}.fs
    fi

    if [ -f "update.app" ]; then
        rm update.app
    fi

    if [ -f "update.fw" ]; then
        rm update.fw
    fi
}

create_fsupdate_template () {
    local fsupdate_template_filename="${DEPLOY_DIR_IMAGE}/${FSUP_TEMPLATE_FILE_NAME}"

    if [ ! -f "${fsupdate_template_filename}" ]; then
        # create json template content
        json_content='{
    "name": "Common F&S Update",
    "version": "1.0",
    "images": {
        "updates" : [
            {
                "description": <fw_update_description>,
                "version": <fw_version>,
                "handler": <fw_handler>,
                "file": "update.fw",
                "hashes": {
                    "sha256": <fw_sha_hash>
                }
            },
            {
                "description": <app_update_description>,
                "version": <app_version>,
                "handler": <app_handler>,
                "file": "update.app",
                "hashes": {
                    "sha256": <app_sha_hash>
                }
            }
        ]
    }
}'
        # write the content into the template file
        echo "${json_content}" > ${fsupdate_template_filename}
    fi
}

# create update images
create_update_images () {
    # create fsupdate template
    create_fsupdate_template
    # create fsupdate images for emmc boot device
    if [[ "${IMAGE_FSTYPES}" == *"ubifs"* ]]; then
        create_fsupdate app fw common nand
    fi
    # create fsupdate images for nand boot device
    if [[ "${IMAGE_FSTYPES}" =~ wic.gz|wic ]]; then
        create_fsupdate app fw common emmc
    fi
}

IMAGE_POSTPROCESS_COMMAND += "create_update_images; "

do_image_update_package[depends] += "mtd-utils-native:do_populate_sysroot"
do_image_update_package[depends] += "squashfs-tools-native:do_populate_sysroot"
do_image_update_package[depends] += "application-container-native:do_populate_sysroot"

do_image_wic[recrdeptask] += "do_image_wic do_image_update_package"
do_image_wic[depends] += "squashfs-tools-native:do_populate_sysroot"
do_image_wic[depends] += "mtd-utils-native:do_populate_sysroot"
do_image_wic[depends] += "python3-pyparted-native:do_populate_sysroot"

ROOTFS_POSTPROCESS_COMMAND += "remove_fw_env_config; "

do_fsup_image_clean () {
    # remove fsupdate directory with all images
    rm -rf "${DEPLOY_DIR_IMAGE}/${FSUP_IMAGE_DIR_NAME}"
    # remove fsupdate template
    rm -rf "${DEPLOY_DIR_IMAGE}/${FSUP_TEMPLATE_FILE_NAME}"
}

do_clean:append () {
    # call fsup_certs_clean function
    bb.build.exec_func('do_fsup_image_clean', d)
}

DISTRO_FEATURES += " rauc"
