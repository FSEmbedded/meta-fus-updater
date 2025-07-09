# classes/cert-handler.bbclass

# Base paths relative to Yocto layer structure
META_FUS_LAYER_BASE     := "${TOPDIR}/../sources/meta-fus-updater"
SCRIPTS_BASE            := "${META_FUS_LAYER_BASE}/scripts"
CERT_BASE_DIR           ??= "${META_FUS_LAYER_BASE}/certs"

# Ensure openssl-native is available in sysroot before running the task
do_generate_certificates[depends] += "openssl-native:do_populate_sysroot"

# Task to generate or validate the certificate infrastructure
python do_generate_certificates() {
    import os
    import subprocess

    d_ = d.getVar

    # Configuration from BitBake variables
    script           = os.path.join(d_("SCRIPTS_BASE"), "generate-certs.sh")
    variant          = d_("BUILD_VARIANT") or "dev"
    purpose          = d_("CERT_PURPOSE") or "system"
    use_intermediate = d_("USE_INTERMEDIATE_CERT") or "1"
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

    # Avoid regeneration if already present (idempotent)
    if os.path.exists(keyring_file):
        bb.note(f"[cert-handler] Keyring already exists at {keyring_file}, skipping generation.")
        return

    # Assemble command
    cmd = [script, f"--env={variant}", f"--purpose={purpose}"]
    if use_intermediate != "1":
        cmd.append("--no-intermediate")

    # Ensure script is executable
    os.chmod(script, 0o755)

    bb.note(f"[cert-handler] Executing: {' '.join(cmd)}")

    # Run the generation script with prepared environment
    try:
        subprocess.run(cmd, check=True, env=env)
    except subprocess.CalledProcessError as e:
        bb.fatal(f"[cert-handler] generate-certs.sh failed (exit code {e.returncode})")
}

# Ensure task runs before configuration
addtask generate_certificates before do_configure
