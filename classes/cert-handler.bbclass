# classes/cert-handler.bbclass

# Cert/signing config defaults (CERT_BASE_DIR, FUS_BUILD_VARIANT, FUS_USE_INTERMEDIATE_CERT)
inherit fus-cert-defaults

# Script base — LAYER_BASE_DIR is set to ${LAYERDIR} in conf/layer.conf
SCRIPTS_BASE            := "${LAYER_BASE_DIR}/scripts"

# Ensure openssl-native is available in sysroot before running the task
do_generate_certificates[depends] += "openssl-native:do_populate_sysroot"

do_generate_certificates[nostamp] = "1"

# Task to generate or validate the certificate infrastructure
python do_generate_certificates() {
    import os
    import subprocess

    d_ = d.getVar

    # Configuration from BitBake variables
    script           = os.path.join(d_("SCRIPTS_BASE"), "generate-certs.sh")
    variant          = d_("FUS_BUILD_VARIANT")
    purpose          = d_("CERT_PURPOSE") or "system"
    use_intermediate = d_("FUS_USE_INTERMEDIATE_CERT")
    cert_base_dir    = d_("CERT_BASE_DIR")

    # Derived paths
    keyring_file     = os.path.join(cert_base_dir, variant, purpose, "keyring.pem")
    cert_dir         = os.path.dirname(keyring_file)

    bb.note(f"[cert-handler] Ensuring certificate output dir exists: {cert_dir}")
    os.makedirs(cert_dir, exist_ok=True)

    # Environment setup for script
    env = os.environ.copy()
    env["CERT_BASE_DIR"] = cert_base_dir

    native_bin       = d_("STAGING_BINDIR_NATIVE")
    full_openssl     = os.path.join(native_bin, "openssl")

    if not os.path.exists(full_openssl):
        bb.fatal(f"[cert-handler] openssl-native binary not found at: {full_openssl}")

    env["OPENSSL_BIN"] = full_openssl

    # Logging for debug
    bb.note(f"[cert-handler] Using OPENSSL_BIN={full_openssl}")
    bb.debug(1, f"[cert-handler] PATH: {env['PATH']}")
    bb.debug(1, f"[cert-handler] HOST_SYSROOT: {d_('HOST_SYSROOT')}")
    bb.debug(1, f"[cert-handler] STAGING_BINDIR_NATIVE: {native_bin}")

    # Behavior for production environments
    if variant == "prod" and not os.path.exists(keyring_file):
        bb.fatal(f"[cert-handler] Production keyring not found at {keyring_file}. Aborting.")

    # Config marker to detect stale certs after setting changes
    config_marker = os.path.join(cert_dir, ".cert-config")
    marker_content = f"variant={variant}\npurpose={purpose}\nuse_intermediate={use_intermediate}\n"
    force_regen = False

    if os.path.exists(keyring_file):
        if os.path.exists(config_marker):
            with open(config_marker) as f:
                stored_marker = f.read()

            if stored_marker == marker_content:
                bb.note(f"[cert-handler] Keyring exists and config matches, skipping generation.")
                return

            # On prod the framework only ever reads. Regenerating would replace the
            # root certificate, and that root is installed into every image as the
            # trust anchor - devices already in the field would be left trusting a
            # key nobody holds any more.
            if variant == "prod":
                bb.fatal(
                    f"[cert-handler] Refusing to regenerate production certificates in {cert_dir}.\n"
                    f"  The stored settings marker does not match this build:\n"
                    f"    on disk:    {stored_marker!r}\n"
                    f"    this build: {marker_content!r}\n"
                    f"  Regenerating would replace the root certificate that every image built\n"
                    f"  from these certs installs as its trust anchor.\n"
                    f"  If this directory was copied from a dev tree it holds development keys:\n"
                    f"  remove it and create production material deliberately. Do not edit the\n"
                    f"  marker to silence this - that satisfies the check and ships the\n"
                    f"  development root as the production trust anchor."
                )

            bb.warn(f"[cert-handler] Certificate config changed, regenerating certificates.")
            force_regen = True
        else:
            bb.note(f"[cert-handler] Keyring already exists at {keyring_file}, skipping generation.")
            return

    # Assemble command
    cmd = [script, f"--env={variant}", f"--purpose={purpose}"]
    if use_intermediate != "1":
        cmd.append("--no-intermediate")
    if force_regen:
        cmd.append("--force")

    # Ensure script is executable
    os.chmod(script, 0o755)

    bb.note(f"[cert-handler] Executing: {' '.join(cmd)}")

    # Run the generation script with prepared environment
    try:
        result = subprocess.run(cmd, check=True, env=env,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.stdout:
            bb.note(result.stdout.decode().strip())
    except subprocess.CalledProcessError as e:
        stderr = e.stderr.decode().strip() if e.stderr else "Unknown error"
        bb.fatal(f"[cert-handler] generate-certs.sh failed (exit code {e.returncode}): {stderr}")

    # Write config marker for future change detection
    with open(config_marker, 'w') as f:
        f.write(marker_content)
}

# Ensure task runs before configuration
addtask generate_certificates before do_configure
