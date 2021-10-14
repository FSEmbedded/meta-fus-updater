
remove_fw_env_config() {
  rm ${IMAGE_ROOTFS}/etc/fw_env.config
}

do_create_application_image() {
    local IMAGE_ROOTFS_FUS_UPDATER_BASE=${IMAGE_ROOTFS}/..
    rm -rf ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/app_image
    mkdir -p ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/app_image
    local IMAGE_APP_FUS_UPDATER=${IMAGE_ROOTFS_FUS_UPDATER_BASE}/app_image

    cp -a ${IMAGE_ROOTFS}/app/* ${IMAGE_APP_FUS_UPDATER}
    rm -rf ${IMAGE_ROOTFS}/app

    # Create application image
    local OUTPUT_IMAGE_NAME=${DEPLOY_DIR_IMAGE}/application_container
    local APP_KEY=${LAYER_BASE_DIR}/rauc/rauc.key.pem
    local APPLICATION_ROOT_FOLDER=${IMAGE_APP_FUS_UPDATER}
    local APPLICATION_IMAGE=${OUTPUT_IMAGE_NAME}_img

	${STAGING_DIR_NATIVE}/usr/bin/package_app -o ${OUTPUT_IMAGE_NAME} -rf ${APPLICATION_ROOT_FOLDER} -ptm ${STAGING_DIR_NATIVE}/usr/sbin/mksquashfs -v ${APPLICATION_VERSION} -kf ${APP_KEY}

    # Copy image into data partition
    cp -a ${APPLICATION_IMAGE} ${IMAGE_ROOTFS}/rw_fs/root/application/app_a.squashfs
    cp -a ${APPLICATION_IMAGE} ${IMAGE_ROOTFS}/rw_fs/root/application/app_b.squashfs
	cp -a ${IMAGE_ROOTFS}/rw_fs/root ${IMAGE_DATA_PARTITION_FUS_UPDATER}
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

	# Create data partition - nand
	${STAGING_DIR_NATIVE}/usr/sbin/mkfs.ubifs -r ${IMAGE_DATA_PARTITION_FUS_UPDATER} -o ${IMGDEPLOYDIR}/${IMAGE_NAME}.data-partition-nand.ubifs ${MKUBIFS_ARGS}

	# Create system partition - nand|emmc
	${STAGING_DIR_NATIVE}/usr/sbin/mksquashfs ${IMAGE_ROOTFS_FUS_UPDATER} ${IMGDEPLOYDIR}/${IMAGE_NAME}.squashfs ${EXTRA_IMAGECMD} -noappend -comp xz

	# Create symlinks
	ln -sf ${IMGDEPLOYDIR}/${IMAGE_NAME}.squashfs ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.squashfs
	ln -sf ${IMGDEPLOYDIR}/${IMAGE_NAME}.data-partition-nand.ubifs ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.data-partition-nand.ubifs
}

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

    d.setVar("RAUC_TEMPLATE_EMMC", d.getVar("LAYER_BASE_DIR"))
    d.appendVar("RAUC_TEMPLATE_EMMC", "/rauc")
    d.appendVar("RAUC_TEMPLATE_EMMC", "/rauc_template_mmc")

    d.setVar("RAUC_TEMPLATE_NAND", d.getVar("LAYER_BASE_DIR"))
    d.appendVar("RAUC_TEMPLATE_NAND", "/rauc")
    d.appendVar("RAUC_TEMPLATE_NAND", "/rauc_template_nand")


    create_rauc_update_mmc(d)
    create_rauc_update_nand(d)
}

def create_rauc_update_mmc(d):
    import subprocess as sp
    import parted, shutil, pathlib

    identify_partition_by_position = dict()
    ###################################
    # Here youc can adapt the partition layout
    identify_partition_by_position["1"] = "uboot.img"
    identify_partition_by_position["5"] = "boot.vfat"

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

IMAGE_CMD_update_package () {
	do_create_squashfs_rootfs_images
}

do_image_update_package[depends] += "mtd-utils-native:do_populate_sysroot"
do_image_update_package[depends] += "squashfs-tools-native:do_populate_sysroot"
do_image_update_package[depends] += "application-container-native:do_populate_sysroot"

do_image_wic[recrdeptask] += "do_image_wic do_image_update_package"
do_image_wic[depends] += "squashfs-tools-native:do_populate_sysroot"
do_image_wic[depends] += "mtd-utils-native:do_populate_sysroot"

ROOTFS_POSTPROCESS_COMMAND += "remove_fw_env_config; "

