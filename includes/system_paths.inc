# Paths for fw_env.config and system.conf used across multiple recipes.
# dynamic_overlay creates symlinks at runtime on the writable overlay,
# pointing to the NAND or eMMC variant on the read-only rootfs.

# fw_env.config is used by the U-Boot tool fw_printenv / fw_setenv
UBOOT_ENV_PATH = "${FUS_PERSISTENT_ROOT}/conf/fw_env.config"
NAND_UBOOT_ENV_PATH = "${sysconfdir}/fw_env.config.nand"
EMMC_UBOOT_ENV_PATH = "${sysconfdir}/fw_env.config.mmc"

# system.conf is used by rauc
RAUC_SYSTEM_CONF_PATH = "${FUS_PERSISTENT_ROOT}/conf/system.conf"
NAND_RAUC_SYSTEM_CONF_PATH = "${sysconfdir}/rauc/system.conf.nand"
EMMC_RAUC_SYSTEM_CONF_PATH = "${sysconfdir}/rauc/system.conf.mmc"
