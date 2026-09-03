# F&S base functions to create update images

inherit fus-updater-defaults

# install host scripts for the build process
DEPENDS = " \
    fus-installscript-native \
    xxd-native \
    openssl-native \
"

# Recreate the historic unqualified artifact name next to the per-image one. The link
# is relative because sstate refuses absolute symlinks pointing into TMPDIR.
# $1 = directory, $2 = real file name, $3 = legacy name
fsup_link_legacy_name() {
    if [ "${FSUP_ARTIFACT_COMPAT}" != "1" ]; then
        return 0
    fi
    if [ "$2" = "$3" ]; then
        return 0
    fi
    ln -sfn "$2" "$1/$3"
}

remove_fw_env_config() {
    # create persistent conf directory
    install -d ${IMAGE_ROOTFS}${FUS_PERSISTENT_ROOT}/conf

    # remove old static configuration in rootfs
    rm -f ${IMAGE_ROOTFS}${sysconfdir}/fw_env.config \
          ${IMAGE_ROOTFS}${sysconfdir}/system.conf

    # Create symbolic links
    ln -sf ${FUS_PERSISTENT_ROOT}/conf/fw_env.config  \
          ${IMAGE_ROOTFS}${sysconfdir}/fw_env.config
    ln -sf ${FUS_PERSISTENT_ROOT}/conf/system.conf    \
          ${IMAGE_ROOTFS}${sysconfdir}/rauc/system.conf
}

# Revised do_create_application_image to support both root and intermediate certificates
# Use chain.cert.pem in sign directory, consistent with RAUC usage.
do_create_application_image() {
    # Deployment-mode branch. The toggle lives in fus-updater-defaults.bbclass
    # (FUS_APPLICATION_DEPLOY_MODE). "container" builds and signs the app squashfs
    # and injects it into the data partition; "rootfs" ships the app as part of the
    # normal rootfs (delivered by a consumer recipe), so there is no container to
    # build or inject here -> no-op. Fail fast on any unknown value.
    case "${FUS_APPLICATION_DEPLOY_MODE}" in
        container) : ;;
        rootfs)
            bbnote "FUS_APPLICATION_DEPLOY_MODE=rootfs: skipping application container creation/injection"
            return 0
            ;;
        *)
            bbfatal "FUS_APPLICATION_DEPLOY_MODE='${FUS_APPLICATION_DEPLOY_MODE}' not supported (container|rootfs)"
            ;;
    esac

    # Validate required variables
    if [ -z "${FUS_BUILD_VARIANT}" ]; then
        bbfatal "FUS_BUILD_VARIANT must be set (prod/dev)"
    fi
    if [ -z "${APPLICATION_VERSION}" ]; then
        bbfatal "APPLICATION_VERSION must be set"
    fi

    # Determine certificate paths. FUS_SIGN_APP_DIR is resolved at parse time so the
    # signing material can be part of this task's hash - see the file-checksums flags
    # at the end of this file.
    local build_variant="${FUS_BUILD_VARIANT}"
    local cert_base="${FUS_SIGN_APP_DIR}"
    local sign_dir="${cert_base}"
    local sign_key="${sign_dir}/sign.key.pem"
    local sign_cert="${sign_dir}/sign.cert.pem"
    local chain_cert="${sign_dir}/chain.cert.pem"

    # Prepare chain cert if intermediate is used
    if [ "${FUS_USE_INTERMEDIATE_CERT}" = "1" ]; then
        local inter_cert="${cert_base}/inter.cert.pem"
        if [ ! -f "${inter_cert}" ]; then
            bbfatal "Intermediate certificate not found: ${inter_cert}"
        fi
        # Create chain cert: sign + intermediate
        cat "${sign_cert}" "${inter_cert}" > "${chain_cert}"
        APP_CERT="${chain_cert}"
    else
        APP_CERT="${sign_cert}"
    fi
    APP_KEY="${sign_key}"

    # Validate signing files
    for f in "${APP_KEY}" "${APP_CERT}"; do
        if [ ! -f "${f}" ]; then
            bbfatal "Signing file not found: ${f}"
        fi
        if [ ! -r "${f}" ]; then
            bbfatal "Signing file not readable: ${f}"
        fi
    done

    # Verify signing cert chains to the root cert deployed as keyring on the device
    local root_cert="${FUS_SIGN_APP_ROOT_DIR}/root.cert.pem"
    if [ ! -f "${root_cert}" ]; then
        bbfatal "Root certificate not found: ${root_cert}"
    fi
    if [ "${FUS_USE_INTERMEDIATE_CERT}" = "1" ]; then
        openssl verify -CAfile "${root_cert}" -untrusted "${inter_cert}" "${sign_cert}" \
            || bbfatal "Signing cert does not chain to root (with intermediate). Regenerate certs."
    else
        openssl verify -CAfile "${root_cert}" "${sign_cert}" \
            || bbfatal "Signing cert does not chain to root (without intermediate). Regenerate certs with --no-intermediate."
    fi

    # Define application image directory
    local IMAGE_ROOTFS_FUS_UPDATER_BASE="${IMAGE_ROOTFS}/.."
    local IMAGE_APP_FUS_UPDATER="${IMAGE_ROOTFS_FUS_UPDATER_BASE}/app_image"
    rm -rf "${IMAGE_APP_FUS_UPDATER}" && mkdir -p "${IMAGE_APP_FUS_UPDATER}"

    # Copy application files
    if [ -d "${APPLICATION_DEPLOY_DIR}" ]; then
        cp -a "${APPLICATION_DEPLOY_DIR}/"* "${IMAGE_APP_FUS_UPDATER}/"
        bbnote "Copied application files from ${APPLICATION_DEPLOY_DIR}"
    else
        bbwarn "No application files found in ${APPLICATION_DEPLOY_DIR}"
    fi

    # Build the container under its unqualified name in a work directory and deploy it
    # under the per-image name afterwards. package_app derives the name of the unsigned
    # image by splitting the given name at its last dot, so building straight into
    # ${FSUP_ARTIFACT_PREFIX}${APPLICATION_CONTAINER_NAME} puts the "_unsigned" marker in
    # the middle of the name instead of at its end.
    local APP_STAGE_DIR="${WORKDIR}/app_container"
    rm -rf "${APP_STAGE_DIR}" && mkdir -p "${APP_STAGE_DIR}"

    # Define output base and validate tools
    local OUTPUT_IMAGE_BASE="${APP_STAGE_DIR}/${APPLICATION_CONTAINER_NAME}"
    local app_version="${APPLICATION_VERSION}"
    for tool in "${STAGING_DIR_NATIVE}/usr/bin/package_app" "${STAGING_DIR_NATIVE}/usr/bin/mksquashfs"; do
        if [ ! -x "${tool}" ]; then
            bbfatal "Required tool not found or not executable: ${tool}"
        fi
    done

    # Create and sign application image
    bbnote "Creating signed application image version ${app_version}"
    "${STAGING_DIR_NATIVE}/usr/bin/package_app" \
        -o "${OUTPUT_IMAGE_BASE}" \
        -rf "${IMAGE_APP_FUS_UPDATER}" \
        -ptm "${STAGING_DIR_NATIVE}/usr/bin/mksquashfs" \
        -v "${app_version}" \
        -kf "${APP_KEY}" \
        -cf "${APP_CERT}" || bbfatal "Failed to create signed application image"

    # Validate created image
    if [ ! -f "${OUTPUT_IMAGE_BASE}" ]; then
        bbfatal "Signed application image creation failed: ${OUTPUT_IMAGE_BASE} not found"
    fi
    # Validate created unsigned image
    if [ ! -f "${OUTPUT_IMAGE_BASE}_unsigned" ]; then
        bbfatal "Application image creation failed: ${OUTPUT_IMAGE_BASE}_unsigned not found"
    fi

    # Deploy under the per-image name - see FSUP_ARTIFACT_PREFIX in
    # fus-updater-defaults.bbclass.
    install -m 0644 "${OUTPUT_IMAGE_BASE}" \
        "${IMGDEPLOYDIR}/${FSUP_ARTIFACT_PREFIX}${APPLICATION_CONTAINER_NAME}"
    install -m 0644 "${OUTPUT_IMAGE_BASE}_unsigned" \
        "${IMGDEPLOYDIR}/${FSUP_ARTIFACT_PREFIX}${APPLICATION_CONTAINER_NAME}_unsigned"

    fsup_link_legacy_name "${IMGDEPLOYDIR}" \
        "${FSUP_ARTIFACT_PREFIX}${APPLICATION_CONTAINER_NAME}" \
        "${APPLICATION_CONTAINER_NAME}"
    fsup_link_legacy_name "${IMGDEPLOYDIR}" \
        "${FSUP_ARTIFACT_PREFIX}${APPLICATION_CONTAINER_NAME}_unsigned" \
        "${APPLICATION_CONTAINER_NAME}_unsigned"

    # Install into rootfs slots
    mkdir -p "${IMAGE_ROOTFS}${FUS_APPLICATION_DIR}"
    for slot in a b; do
        cp -a "${OUTPUT_IMAGE_BASE}_unsigned" "${IMAGE_ROOTFS}${FUS_APPLICATION_DIR}/app_${slot}.squashfs" \
            || bbfatal "Failed to copy to app_${slot}.squashfs"
        chown root:root "${IMAGE_ROOTFS}${FUS_APPLICATION_DIR}/app_${slot}.squashfs"
        chmod 644 "${IMAGE_ROOTFS}${FUS_APPLICATION_DIR}/app_${slot}.squashfs"
    done

    bbnote "Application image creation completed successfully"
}

do_create_squashfs_rootfs_images() {

    local IMAGE_ROOTFS_FUS_UPDATER_BASE=${IMAGE_ROOTFS}/..

    rm -rf ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/rootfs_temp
    rm -rf ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/data_partition

    mkdir -p ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/rootfs_temp
    mkdir -p ${IMAGE_ROOTFS_FUS_UPDATER_BASE}/data_partition

    local IMAGE_DATA_PARTITION_FUS_UPDATER=${IMAGE_ROOTFS_FUS_UPDATER_BASE}/data_partition
    local IMAGE_ROOTFS_FUS_UPDATER=${IMAGE_ROOTFS_FUS_UPDATER_BASE}/rootfs_temp

    # container mode keeps the app under FUS_APPLICATION_DIR (overlay mount point);
    # rootfs mode ships the app in the rootfs itself, so this dir is not needed.
    if [ "${FUS_APPLICATION_DEPLOY_MODE}" = "container" ]; then
        mkdir -p ${IMAGE_ROOTFS}${FUS_APPLICATION_DIR}/current
    fi
    cp -a ${IMAGE_ROOTFS}/* ${IMAGE_ROOTFS_FUS_UPDATER}

    rm -rf ${IMAGE_ROOTFS_FUS_UPDATER}/app

    # no-op in rootfs mode (early return inside the function)
    do_create_application_image

    cp -a ${IMAGE_ROOTFS}${FUS_PERSISTENT_ROOT}/* ${IMAGE_DATA_PARTITION_FUS_UPDATER}

    # create fsupdate images for nand boot device
    if [[ "${IMAGE_FSTYPES}" == *"ubifs"* ]]; then
        # Create data partition - nand
        ${STAGING_DIR_NATIVE}/usr/sbin/mkfs.ubifs -r ${IMAGE_DATA_PARTITION_FUS_UPDATER} \
            -o ${IMGDEPLOYDIR}/${IMAGE_NAME}.data-partition-nand.ubifs ${MKUBIFS_ARGS}

        if [ ! -f "${IMGDEPLOYDIR}/${IMAGE_NAME}.data-partition-nand.ubifs" ]; then
            bbfatal "Rootfs squashfs creation failed: ${IMGDEPLOYDIR}/${IMAGE_NAME}.data-partition-nand.ubifs not found"
        fi

        cur_dir=$(pwd)
        cd ${IMGDEPLOYDIR}
        ln -sf ${IMAGE_NAME}.data-partition-nand.ubifs ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.data-partition-nand.ubifs
        cd "$cur_dir"
    fi

    # create fsupdate images for emmc boot device
    if [[ "${IMAGE_FSTYPES}" =~ wic.gz|wic ]]; then
        # Create system partition - emmc
        ${STAGING_DIR_NATIVE}/usr/bin/mksquashfs ${IMAGE_ROOTFS_FUS_UPDATER} \
            ${IMGDEPLOYDIR}/${IMAGE_NAME}.squashfs -noappend ${SQUASHFS_EXTRA_IMAGECMD}

        if [ ! -f "${IMGDEPLOYDIR}/${IMAGE_NAME}.squashfs" ]; then
            bbfatal "Rootfs squashfs creation failed: ${IMGDEPLOYDIR}/${IMAGE_NAME}.squashfs not found"
        fi
        # create link in image deploy directory
        cur_dir=$(pwd)
        cd ${IMGDEPLOYDIR}
        ln -sf ${IMAGE_NAME}.squashfs ${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.squashfs
        cd "$cur_dir"
    fi
}

python do_create_update_package() {
    import os
    import shutil
    import pathlib
    import subprocess as sp
    import parted
    import bb

    build_variant = d.getVar('FUS_BUILD_VARIANT') or 'dev'
    use_intermediate = d.getVar('FUS_USE_INTERMEDIATE_CERT') == '1'

    layer_dir = d.getVar('LAYER_BASE_DIR')
    base_rauc_dir = os.path.join(layer_dir, 'rauc')
    # Resolved at parse time so the signing material can be part of this task's hash -
    # see the file-checksums flags at the end of this file.
    base_cert_dir = d.getVar('FUS_SIGN_SYSTEM_DIR')
    sign_dir = os.path.join(base_cert_dir)
    inter_dir = os.path.join(base_cert_dir)

    sign_cert = os.path.join(sign_dir, 'sign.cert.pem')
    sign_key = os.path.join(sign_dir, 'sign.key.pem')

    # Debug output: Certificate paths and existence
    bb.note("=== RAUC Certificate Debug Information ===")
    bb.note(f"Build variant: {build_variant}")
    bb.note(f"Use intermediate cert: {use_intermediate}")
    bb.note(f"Base certificate directory: {base_cert_dir}")
    bb.note(f"Sign directory: {sign_dir}")
    bb.note(f"Sign certificate: {sign_cert}")
    bb.note(f"Sign key: {sign_key}")

    # Check file existence
    if os.path.exists(sign_cert):
        bb.note(f"✓ Sign certificate exists: {sign_cert}")
    else:
        bb.error(f"✗ Sign certificate missing: {sign_cert}")

    if os.path.exists(sign_key):
        bb.note(f"✓ Sign key exists: {sign_key}")
    else:
        bb.error(f"✗ Sign key missing: {sign_key}")

    # Display certificate details
    if os.path.exists(sign_cert):
        try:
            cert_info = sp.check_output(['openssl', 'x509', '-in', sign_cert, '-noout', '-subject', '-issuer', '-dates'],
                                      text=True, stderr=sp.STDOUT)
            bb.note("Sign certificate details:")
            for line in cert_info.strip().split('\n'):
                bb.note(f"  {line}")
        except sp.CalledProcessError as e:
            bb.warn(f"Could not read certificate details: {e}")

    d.setVar('RAUC_KEY', sign_key)

    # Set RAUC_CERT and optionally RAUC_INTERMEDIATE_CERT
    if use_intermediate:
        inter_cert = os.path.join(inter_dir, 'inter.cert.pem')
        bb.note(f"Intermediate certificate: {inter_cert}")

        if not os.path.exists(inter_cert):
            bb.fatal(f"Intermediate certificate not found: {inter_cert}")
        else:
            bb.note(f"✓ Intermediate certificate exists: {inter_cert}")

        # Display intermediate certificate details
        try:
            inter_cert_info = sp.check_output(['openssl', 'x509', '-in', inter_cert, '-noout', '-subject', '-issuer', '-dates'],
                                            text=True, stderr=sp.STDOUT)
            bb.note("Intermediate certificate details:")
            for line in inter_cert_info.strip().split('\n'):
                bb.note(f"  {line}")
        except sp.CalledProcessError as e:
            bb.warn(f"Could not read intermediate certificate details: {e}")

        d.setVar('RAUC_CERT', sign_cert)
        d.setVar('RAUC_INTERMEDIATE_CERT', inter_cert)
        bb.note(f"RAUC_CERT set to: {sign_cert}")
        bb.note(f"RAUC_INTERMEDIATE_CERT set to: {inter_cert}")
    else:
        d.setVar('RAUC_CERT', sign_cert)
        d.setVar('RAUC_INTERMEDIATE_CERT', '')
        bb.note(f"RAUC_CERT set to: {sign_cert}")
        bb.note("RAUC_INTERMEDIATE_CERT set to empty (no intermediate)")

    bb.note(f"RAUC_KEY set to: {sign_key}")

    # Standard paths
    rauc_template_nand = os.path.join(base_rauc_dir, 'rauc_template_nand')
    rauc_template_emmc = os.path.join(base_rauc_dir, 'rauc_template_mmc')
    rauc_binary = os.path.join(d.getVar('DEPLOY_DIR_TOOLS') or '', 'rauc')

    d.setVar('RAUC_TEMPLATE_NAND', rauc_template_nand)
    d.setVar('RAUC_TEMPLATE_EMMC', rauc_template_emmc)
    d.setVar('RAUC_BINARY', rauc_binary)

    # Debug output: Template and binary paths
    bb.note(f"RAUC binary: {rauc_binary}")
    bb.note(f"RAUC template NAND: {rauc_template_nand}")
    bb.note(f"RAUC template eMMC: {rauc_template_emmc}")

    # Check template directories
    if os.path.exists(rauc_template_nand):
        bb.note(f"✓ NAND template directory exists")
    else:
        bb.warn(f"✗ NAND template directory missing: {rauc_template_nand}")

    if os.path.exists(rauc_template_emmc):
        bb.note(f"✓ eMMC template directory exists")
    else:
        bb.warn(f"✗ eMMC template directory missing: {rauc_template_emmc}")

    # Check RAUC binary
    if os.path.exists(rauc_binary):
        bb.note(f"✓ RAUC binary exists: {rauc_binary}")
        try:
            rauc_version = sp.check_output([rauc_binary, '--version'], text=True, stderr=sp.STDOUT)
            bb.note(f"RAUC version: {rauc_version.strip()}")
        except sp.CalledProcessError as e:
            bb.warn(f"Could not get RAUC version: {e}")
    else:
        bb.error(f"✗ RAUC binary missing: {rauc_binary}")

    img_name = d.getVar('IMAGE_LINK_NAME')
    d.setVar('RAUC_IMG_WIC', os.path.join(d.getVar('IMGDEPLOYDIR'), f"{img_name}.wic"))
    d.setVar('RAUC_IMG_ROOTFS', os.path.join(d.getVar('IMGDEPLOYDIR'), f"{img_name}.squashfs"))
    img_name=d.getVar('KERNEL_IMAGETYPE')
    d.setVar('RAUC_IMG_KERNEL', os.path.join(d.getVar('DEPLOY_DIR_IMAGE'), f"{img_name}"))

    dtb_file = d.getVar('KERNEL_DEVICETREE').split()[0].split('/')[-1]
    d.setVar('RAUC_IMG_DEVICE_TREE', os.path.join(d.getVar('DEPLOY_DIR_IMAGE'), dtb_file))

    # Debug output: Image files
    rauc_img_wic = d.getVar('RAUC_IMG_WIC')
    rauc_img_rootfs = d.getVar('RAUC_IMG_ROOTFS')
    rauc_img_kernel = d.getVar('RAUC_IMG_KERNEL')
    rauc_img_dtb = d.getVar('RAUC_IMG_DEVICE_TREE')

    bb.note("=== RAUC Image Files ===")
    bb.note(f"WIC image: {rauc_img_wic}")
    bb.note(f"Rootfs image: {rauc_img_rootfs}")
    bb.note(f"Kernel image: {rauc_img_kernel}")
    bb.note(f"Device tree: {rauc_img_dtb}")

    image_fstypes = d.getVar('IMAGE_FSTYPES') or ''

    # Only warn about images this configuration actually builds. On a configuration
    # without wic in IMAGE_FSTYPES the WIC image is absent by design, and the warning
    # said the update package was incomplete when nothing was missing.
    checked = [(rauc_img_rootfs, "Rootfs"), (rauc_img_kernel, "Kernel"),
               (rauc_img_dtb, "Device Tree")]
    if 'wic' in image_fstypes:
        checked.insert(0, (rauc_img_wic, "WIC"))
    else:
        bb.note(f"WIC image is not part of IMAGE_FSTYPES, not checked: {rauc_img_wic}")

    # Check image files existence
    for img_path, img_type in checked:
        if os.path.exists(img_path):
            file_size = os.path.getsize(img_path)
            bb.note(f"✓ {img_type} image exists ({file_size} bytes): {img_path}")
        else:
            bb.warn(f"✗ {img_type} image missing: {img_path}")
    bb.note(f"Image fstypes: {image_fstypes}")
    bb.note("=== End Certificate Debug Information ===")

    if 'ubifs' in image_fstypes:
        bb.note("Creating RAUC update for NAND...")
        create_rauc_update_nand(d)
    if 'wic' in image_fstypes:
        bb.note("Creating RAUC update for eMMC...")
        create_rauc_update_mmc(d)
}

def fsup_link_legacy(d, directory, real_name, legacy_name):
    """Recreate the historic unqualified artifact name as a relative symlink.

    Relative because sstate refuses absolute symlinks pointing into TMPDIR. The link
    belongs to whichever image was deployed last, so it means "installed last", not
    "built last".
    """
    import os

    if d.getVar('FSUP_ARTIFACT_COMPAT') != '1' or real_name == legacy_name:
        return
    link = os.path.join(directory, legacy_name)
    if os.path.lexists(link):
        os.remove(link)
    os.symlink(real_name, link)


def fsup_stamp_bundle_version(d, staging_dir):
    """Fill the version placeholder in the bundle manifest.

    compatible= is compared against the device's system.conf and must stay as it is; the
    version is what tells one product image's bundle from another's when inspecting it.
    """
    import os
    import bb

    manifest = os.path.join(staging_dir, 'manifest.raucm')
    if not os.path.exists(manifest):
        bb.warn(f"manifest.raucm missing in template, cannot set the bundle version: {manifest}")
        return

    version = "%s-%s" % (d.getVar('IMAGE_BASENAME'), d.getVar('FIRMWARE_VERSION'))
    with open(manifest, 'r+') as f:
        content = f.read().replace('${bundle_version}', version)
        f.seek(0)
        f.write(content)
        f.truncate()


def create_rauc_update_mmc(d):
    import os
    import shutil
    import pathlib
    import subprocess as sp
    import parted
    import bb

    def check_cert_for_codesign(cert_path, require_digital_signature=True):
        try:
            output = sp.check_output(['openssl', 'x509', '-in', cert_path, '-noout', '-text'], text=True)
        except sp.CalledProcessError as e:
            bb.fatal(f"Failed to parse certificate {cert_path}: {e.stderr}")

        if 'Extended Key Usage' not in output or 'Code Signing' not in output:
            bb.fatal(f"Certificate {cert_path} missing required extendedKeyUsage=codeSigning")

        if require_digital_signature:
            if 'X509v3 Key Usage' in output and 'Digital Signature' not in output:
                bb.fatal(f"Certificate {cert_path} has keyUsage but is missing digitalSignature")

    # Check required variables
    required_vars = ['RAUC_BINARY', 'RAUC_CERT', 'RAUC_KEY', 'RAUC_IMG_WIC', 'RAUC_TEMPLATE_EMMC']
    for var in required_vars:
        if not d.getVar(var):
            bb.fatal(f"Variable {var} is not defined")

    rauc_bin = d.getVar('RAUC_BINARY')
    cert = d.getVar('RAUC_CERT')
    key = d.getVar('RAUC_KEY')
    inter_cert = d.getVar('RAUC_INTERMEDIATE_CERT') or None
    wic_img = d.getVar('RAUC_IMG_WIC')
    rootfs_img = d.getVar('RAUC_IMG_ROOTFS')
    template = d.getVar('RAUC_TEMPLATE_EMMC')
    imgdeploydir = d.getVar('IMGDEPLOYDIR')
    prefix = d.getVar('FSUP_ARTIFACT_PREFIX') or ''

    # Staging below WORKDIR. It used to sit in the shared deploy directory, where the
    # rmtree below removed the staging tree of any image running at the same time.
    out_dir = os.path.join(d.getVar('WORKDIR'), 'rauc_update_mmc')

    # Validate certificates have codeSigning extendedKeyUsage
    check_cert_for_codesign(cert, require_digital_signature=True)
    if inter_cert:
        check_cert_for_codesign(inter_cert, require_digital_signature=False)

    # Verify input files exist
    if not os.path.exists(wic_img):
        bb.fatal(f"Required WIC image file {wic_img} does not exist")
    if not os.path.exists(rootfs_img):
        bb.fatal(f"Required squashfs file {rootfs_img} does not exist")

    shutil.rmtree(out_dir, ignore_errors=True)
    pathlib.Path(out_dir).mkdir(parents=True)

    # Copy template files
    res = sp.run(['cp', '-r', f"{template}/.", out_dir], capture_output=True)
    if res.returncode != 0:
        bb.fatal(f"Copy template failed: {res.stderr.decode().strip()}")

    part_map = {'1': 'boot.vfat'}

    device = parted.getDevice(wic_img)
    disk = parted.newDisk(device)
    bs = device.sectorSize

    # Extract partitions via dd
    for p in disk.partitions:
        num = str(p.number)
        if num in part_map:
            out_file = os.path.join(out_dir, part_map[num])
            cmd = [
                'dd',
                f'if={wic_img}',
                f'of={out_file}',
                f'bs={bs}',
                f'count={p.getLength(unit="sectors")}',
                f'skip={p.geometry.start}',
                'status=none'
            ]
            r = sp.run(cmd, capture_output=True)
            if r.returncode != 0:
                bb.fatal(f"dd error: {r.stderr.decode().strip()}")

    shutil.copyfile(rootfs_img, os.path.join(out_dir, 'rootfs.squashfs'))

    fsup_stamp_bundle_version(d, out_dir)

    artifact_name = f"{prefix}rauc_update_emmc.artifact"
    artifact = os.path.join(imgdeploydir, artifact_name)
    if os.path.isfile(artifact):
        os.remove(artifact)

    cmd = [rauc_bin, 'bundle', '--key', key, '--cert', cert]
    if inter_cert:
        cmd.extend(['--intermediate', inter_cert])
    cmd.extend([out_dir, artifact])

    bb.note(f"Running RAUC bundle command: {' '.join(cmd)}")

    r = sp.run(cmd, capture_output=True)
    if r.returncode != 0:
        bb.fatal(f"RAUC bundle eMMC failed: {r.stderr.decode().strip()}")

    fsup_link_legacy(d, imgdeploydir, artifact_name, 'rauc_update_emmc.artifact')

    shutil.rmtree(out_dir)

def create_rauc_update_nand(d):
    import os, shutil, pathlib, subprocess as sp, bb

    # Ensure variables are defined
    required_vars = ['RAUC_BINARY', 'RAUC_CERT', 'RAUC_KEY', 'RAUC_TEMPLATE_NAND',
                     'RAUC_IMG_ROOTFS', 'RAUC_IMG_DEVICE_TREE', 'RAUC_IMG_KERNEL',
                     'KERNEL_DEVICETREE']
    for var in required_vars:
        if not d.getVar(var):
            bb.fatal(f"Variable {var} is not defined")

    path_to_rauc = d.getVar('RAUC_BINARY')
    path_to_cert = d.getVar('RAUC_CERT')
    path_to_key = d.getVar('RAUC_KEY')
    inter_cert = d.getVar('RAUC_INTERMEDIATE_CERT') or None
    template = d.getVar('RAUC_TEMPLATE_NAND')
    rootfs = d.getVar('RAUC_IMG_ROOTFS')
    dtb = d.getVar('RAUC_IMG_DEVICE_TREE')
    kernel = d.getVar('RAUC_IMG_KERNEL')
    imgdeploydir = d.getVar('IMGDEPLOYDIR')
    prefix = d.getVar('FSUP_ARTIFACT_PREFIX') or ''

    # Verify input files exist
    for path, label in [(rootfs, "rootfs"), (dtb, "device tree"), (kernel, "kernel"), (template, "template dir")]:
        if not os.path.exists(path):
            bb.fatal(f"{label} file not found at: {path}")

    # Staging below WORKDIR - see the note in create_rauc_update_mmc.
    out = os.path.join(d.getVar('WORKDIR'), 'rauc_update_nand')
    shutil.rmtree(out, ignore_errors=True)
    pathlib.Path(out).mkdir(parents=True)

    # Copy template
    res = sp.run(['cp', '-r', f"{template}/.", out], capture_output=True)
    if res.returncode != 0:
        bb.fatal(f"Template NAND copy failed:\n{res.stderr.decode().strip()}")

    # Copy images
    shutil.copyfile(rootfs, os.path.join(out, 'rootfs.squashfs'))
    shutil.copyfile(kernel, os.path.join(out, 'Image.img'))

    dtb_path = d.getVar('KERNEL_DEVICETREE').split()[0]
    dtb_filename = os.path.basename(dtb_path).replace('.dtb', '.img')

    shutil.copyfile(dtb, os.path.join(out, dtb_filename))

    # Replace placeholders in template files
    for fname in ('install-check', 'manifest.raucm'):
        fpath = os.path.join(out, fname)
        if not os.path.exists(fpath):
            bb.warn(f"{fname} missing in template, skipping placeholder replacement")
            continue
        with open(fpath, 'r+') as f:
            content = f.read().replace('${fdt_img}', dtb_filename)
            f.seek(0)
            f.write(content)
            f.truncate()

    fsup_stamp_bundle_version(d, out)

    artifact_name = f"{prefix}rauc_update_nand.artifact"
    artifact = os.path.join(imgdeploydir, artifact_name)

    # Remove existing artifact file, if present
    if os.path.isfile(artifact):
        os.remove(artifact)

    # Build RAUC bundle command (with intermediate cert support like eMMC)
    cmd = [path_to_rauc, 'bundle', '--key', path_to_key, '--cert', path_to_cert]
    if inter_cert:
        cmd.extend(['--intermediate', inter_cert])
    cmd.extend([out, artifact])

    bb.note(f"Running RAUC bundle command: {' '.join(cmd)}")  # Added: debug output

    r = sp.run(cmd, capture_output=True)
    if r.returncode != 0:
        bb.fatal(f"RAUC bundle NAND failed: {r.stderr.decode().strip()}")

    fsup_link_legacy(d, imgdeploydir, artifact_name, 'rauc_update_nand.artifact')

    shutil.rmtree(out)


IMAGE_CMD:update_package () {
    do_create_squashfs_rootfs_images
}

create_fsupdate () {
    local update_description_file=fsupdate-common.json
    local prov_service_dir_name="${FS_PROVISIONING_SERVICE_DIR_NAME}"
    local fsup_image_dir_name="${FSUP_IMAGE_DIR_NAME}"
    local fsup_images_dir=${IMGDEPLOYDIR}/${fsup_image_dir_name}
    # Staging below WORKDIR. It used to live inside the shared deploy directory, where
    # the rm -rf below removed the staging tree of any image running at the same time.
    local fsup_images_work_dir=${WORKDIR}/${fsup_image_dir_name}.work
    local prov_service_home=${DEPLOY_DIR_IMAGE}/${prov_service_dir_name}
    local update_desc_file=${fsup_images_work_dir}/${update_description_file}
    local update_name=""

    if [ "$1" = "common" ] || [ "$2" = "common" ]; then
        bbwarn "value common for first or second argument is not allowed."
        return 0
    fi
    # remove work dir if available
    rm -rf ${fsup_images_work_dir}

    args="$1 $2"

    for fsupdate_type in $args
    do
        case $fsupdate_type in
        app)
            UPDATE_FILE_NAME=${APPLICATION_CONTAINER_NAME}
            update_version=${APPLICATION_VERSION}
            update_handler="fus\/application"
            remove_block=6,14d
            target_archiv_name="application"
            update_name="Application"
        ;;
        fw)
            UPDATE_FILE_NAME="rauc_update_${4}.artifact"
            update_version=${FIRMWARE_VERSION}
            update_handler="fus\/firwmware"
            remove_block=14,22d
            target_archiv_name="firmware_${4}"
            update_name="Firmware"
        ;;
        *)
            bbwarn "unknown parameter"
            return 1
        esac

        target=update.${fsupdate_type}

        # create binaries directory with update images
        mkdir -p ${fsup_images_work_dir}
        # create update
        cp -f ${IMGDEPLOYDIR}/${FSUP_ARTIFACT_PREFIX}${UPDATE_FILE_NAME} ${fsup_images_work_dir}/${target}
        # calculate sha256 sum
        update_sha256sum=$(sha256sum -- "${fsup_images_work_dir}/${target}" | awk '{print $1}')

        if [ ! -f "${update_desc_file}" ]; then
            # copy the update description template
            cp -f ${IMGDEPLOYDIR}/${FSUP_ARTIFACT_PREFIX}${FSUP_TEMPLATE_FILE_NAME} ${update_desc_file}
        fi
        #
        sed -i "s|<${fsupdate_type}_update_description>|\"FUS ${update_name} Update\"|g" "${update_desc_file}"
        sed -i "s|<${fsupdate_type}_version>|\"${update_version}\"|g" "${update_desc_file}"
        sed -i "s|<${fsupdate_type}_handler>|\"${update_handler}\"|g" "${update_desc_file}"
        sed -i "s|<${fsupdate_type}_sha_hash>|\"${update_sha256sum}\"|g" "${update_desc_file}"
        sed -i "s|<${fsupdate_type}_name>|\"${target}\"|g" "${update_desc_file}"

        cp -f ${update_desc_file} ${fsup_images_work_dir}/fsupdate.json

        # remove firmware/application update block
        sed -i "$remove_block" ${fsup_images_work_dir}/fsupdate.json

        mkdir -p ${fsup_images_dir}
        cd ${fsup_images_work_dir}
        ${FAKEROOTCMD} tar cfvj ${target_archiv_name}.tar.bz2 --numeric-owner fsupdate.json $target
        # use addfsheader script from native package
        ${FAKEROOTCMD} addfsheader.sh -t CERT ${fsup_images_work_dir}/${target_archiv_name}.tar.bz2 > \
            ${fsup_images_dir}/${FSUP_ARTIFACT_PREFIX}${target_archiv_name}.fs
        fsup_link_legacy_name "${fsup_images_dir}" \
            "${FSUP_ARTIFACT_PREFIX}${target_archiv_name}.fs" "${target_archiv_name}.fs"
        rm -f ${fsup_images_work_dir}/fsupdate.json
    done

    if [ "$3" = "common" ]; then
        # check param 3 for combinded update
        cp -f ${update_desc_file} ${fsup_images_work_dir}/fsupdate.json
        mkdir -p ${fsup_images_dir}
        cd ${fsup_images_work_dir}
        ${FAKEROOTCMD} tar cfvj update_${4}.tar.bz2 --numeric-owner fsupdate.json update.app update.fw
        # use addfsheader script from native package
        ${FAKEROOTCMD} addfsheader.sh -t CERT ${fsup_images_work_dir}/update_${4}.tar.bz2 > \
            ${fsup_images_dir}/${FSUP_ARTIFACT_PREFIX}update_${4}.fs
        fsup_link_legacy_name "${fsup_images_dir}" \
            "${FSUP_ARTIFACT_PREFIX}update_${4}.fs" "update_${4}.fs"
    fi

    if [ -f "update.app" ]; then
        rm update.app
    fi

    if [ -f "update.fw" ]; then
        rm update.fw
    fi
}

create_fsupdate_template () {
    local fsupdate_template_filename="${IMGDEPLOYDIR}/${FSUP_ARTIFACT_PREFIX}${FSUP_TEMPLATE_FILE_NAME}"

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
                "file": <fw_name>,
                "hashes": {
                    "sha256": <fw_sha_hash>
                }
            },
            {
                "description": <app_update_description>,
                "version": <app_version>,
                "handler": <app_handler>,
                "file": <app_name>,
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

    fsup_link_legacy_name "${IMGDEPLOYDIR}" \
        "${FSUP_ARTIFACT_PREFIX}${FSUP_TEMPLATE_FILE_NAME}" "${FSUP_TEMPLATE_FILE_NAME}"
}

# create update images
create_update_images () {
    # create fsupdate template
    create_fsupdate_template
    # container mode emits an app-only and a combined (common) update alongside the
    # firmware update; rootfs mode has no separate app artifact, so only the
    # firmware update is produced (the app ships inside the rootfs/firmware).
    if [ "${FUS_APPLICATION_DEPLOY_MODE}" = "rootfs" ]; then
        # create fsupdate images for nand boot device
        if [[ "${IMAGE_FSTYPES}" == *"ubifs"* ]]; then
            create_fsupdate fw "" "" nand
        fi
        # create fsupdate images for emmc boot device
        if [[ "${IMAGE_FSTYPES}" =~ wic.gz|wic ]]; then
            create_fsupdate fw "" "" emmc
        fi
    else
        # create fsupdate images for nand boot device
        if [[ "${IMAGE_FSTYPES}" == *"ubifs"* ]]; then
            create_fsupdate app fw common nand
        fi
        # create fsupdate images for emmc boot device
        if [[ "${IMAGE_FSTYPES}" =~ wic.gz|wic ]]; then
            create_fsupdate app fw common emmc
        fi
    fi
}

IMAGE_POSTPROCESS_COMMAND += "create_update_images; "

do_image_update_package[depends] += "mtd-utils-native:do_populate_sysroot"
do_image_update_package[depends] += "squashfs-tools-native:do_populate_sysroot"
# package_app (from application-container-native) is only needed to build/sign the
# app container in container mode; rootfs mode does not create a container.
do_image_update_package[depends] += "${@'application-container-native:do_populate_sysroot' if d.getVar('FUS_APPLICATION_DEPLOY_MODE') == 'container' else ''}"

do_create_update_package[depends] += "openssl-native:do_populate_sysroot"

do_image_wic[recrdeptask] += "do_image_update_package"
do_image_wic[depends] += "squashfs-tools-native:do_populate_sysroot"
do_image_wic[depends] += "mtd-utils-native:do_populate_sysroot"
do_image_wic[depends] += "python3-pyparted-native:do_populate_sysroot"

ROOTFS_POSTPROCESS_COMMAND:append = "remove_fw_env_config; "

# There used to be a do_fsup_image_clean here that removed the shared update directory
# and the description template on clean - which took every other image's artifacts with
# it. Both now go through IMGDEPLOYDIR, so a clean removes this recipe's own entries via
# the sstate manifest and nothing else.

# The signing material is not part of any hash bitbake computes today: the paths come
# from configuration and only the file content decides whether an artifact is valid.
# Without these a regenerated certificate leaves a valid stamp behind, and the artifacts
# signed with the previous one stay in place.
def fsup_sign_file_checksums(d, purpose):
    import os

    if purpose == 'app':
        if d.getVar('FUS_APPLICATION_DEPLOY_MODE') != 'container':
            return ''
        base = d.getVar('FUS_SIGN_APP_DIR')
    else:
        base = d.getVar('FUS_SIGN_SYSTEM_DIR')

    names = ['sign.key.pem', 'sign.cert.pem']
    if d.getVar('FUS_USE_INTERMEDIATE_CERT') == '1':
        names.append('inter.cert.pem')
    return ' '.join('%s:True' % os.path.join(base, n) for n in names)

do_create_update_package[file-checksums] += "${@fsup_sign_file_checksums(d, 'system')}"
do_image_update_package[file-checksums] += "${@fsup_sign_file_checksums(d, 'app')}"

DISTRO_FEATURES += " rauc"
