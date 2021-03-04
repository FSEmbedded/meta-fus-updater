do_create_nand_packages() {
	# Copy RootFS temporarly for removing of /rw_fs/root/*

	local IMAGE_ROOTFS_FUS_UPDATER_BASE=${IMAGE_ROOTFS}/..

	rm -rf ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/rootfs_temp
	rm -rf ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/data_partition

	mkdir -p ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/rootfs_temp
	mkdir -p ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/data_partition

	local IMAGE_DATA_PARTITION_FUS_UPDATER=${IMAGE_ROOTFS_FUS_UPDATER_BASE}/data_partition
	local IMAGE_ROOTFS_FUS_UPDATER=${IMAGE_ROOTFS_FUS_UPDATER_BASE}/rootfs_temp

	cp -r ${IMAGE_ROOTFS} ${IMAGE_ROOTFS_FUS_UPDATER}
	rm -rf ${IMAGE_ROOTFS_FUS_UPDATER}/rw_fs/root/*
	cp -r ${IMAGE_ROOTFS}/rw_fs/root/ ${IMAGE_DATA_PARTITION_FUS_UPDATER}

	# Create data partition
	mkfs.ubifs -r ${IMAGE_DATA_PARTITION_FUS_UPDATER} -o ${IMGDEPLOYDIR}/${IMAGE_NAME}.data-partition-nand.ubifs ${MKUBIFS_ARGS}

	#Create system partition
	mksquashfs ${IMAGE_ROOTFS_FUS_UPDATER} ${IMGDEPLOYDIR}/${IMAGE_NAME}.nand.squashfs -noappend

	#Create Symlinks
	cd ${IMGDEPLOYDIR}
	ln -sf ${IMAGE_NAME}.nand.squashfs ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.nand.squashfs
	ln -sf ${IMAGE_NAME}.data-partition-nand.ubifs ${DEPLOY_DIR_IMAGE}/${IMAGE_LINK_NAME}.data-partition-nand.ubifs
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
    d.appendVar("RAUC_IMG_ROOTFS", d.getVar("IMAGE_NAME") + ".nand.squashfs")

    d.setVar("RAUC_IMG_KERNEL", d.getVar("DEPLOY_DIR_IMAGE"))
    d.appendVar("RAUC_IMG_KERNEL", "/Image")

    d.setVar("RAUC_IMG_DEVICE_TREE", d.getVar("DEPLOY_DIR_IMAGE"))
    d.appendVar("RAUC_IMG_DEVICE_TREE", "/imx-boot-tools")
    d.appendVar("RAUC_IMG_DEVICE_TREE", "/")
    d.appendVar("RAUC_IMG_DEVICE_TREE", d.getVar("UBOOT_DTB_NAME"))

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
    identify_partition_by_position[1] = "uboot.img"
    identify_partition_by_position[5] = "boot.vfat"
    identify_partition_by_position[7] = "rootfs.squashfs"

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
        if partiton.number in identify_partition_by_position.keys():
            count_blocks = partiton.getLength(unit='sectors')
            skip = partiton.geometry.start
            dd(input_file=d.getVar("RAUC_IMG_WIC"),
                output_file=os.path.join(dest_dir_mmc, identify_partition_by_position[partiton.number]),
                count=count_blocks,
                skip=skip,
                bs=block_size)

    input_dir_mmc = dest_dir_mmc
    output_file_mmc = os.path.join(d.getVar("DEPLOY_DIR_IMAGE"), "rauc_update_emmc.artifact")

    try:
        os.remove(output_file_mmc)
    except:
        pass

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
    shutil.copyfile(d.getVar("RAUC_IMG_DEVICE_TREE"), input_dir_nand + "/" + d.getVar("UBOOT_DTB_NAME") + ".img")
    shutil.copyfile(d.getVar("RAUC_IMG_KERNEL"), input_dir_nand + "/Image.img")

    with open(input_dir_nand + "/install-check", "r+") as file:
        filedata = file.read().replace("${fdt_img}", d.getVar("UBOOT_DTB_NAME") + ".img")
        file.seek(0)
        file.write(filedata)

    with open(input_dir_nand + "/manifest.raucm", "r+") as file:
        filedata = file.read().replace("${fdt_img}", d.getVar("UBOOT_DTB_NAME") + ".img")
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

addtask do_create_nand_packages after do_rootfs before do_image
addtask do_create_update_package after do_image_wic before do_image_complete

do_create_nand_packages[depends] += "mtd-utils-native:do_populate_sysroot"
do_create_nand_packages[depends] += "squashfs-tools-native:do_populate_sysroot"
