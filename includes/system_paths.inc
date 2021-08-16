# Set paths for fw_env.config and system_conf. These links are used in dynamic_overlay to
# Create a softlink to the file that is matching the memory configuration.

# fw_env.config is used by the U-Boot toll fw_printenv / fw_setenv
UBOOT_ENV_PATH = "${sysconfdir}/fw_env.config"
NAND_UBOOT_ENV_PATH = "${sysconfdir}/fw_env.config.nand"
EMMC_UBOOT_ENV_PATH = "${sysconfdir}/fw_env.config.mmc"

# system.conf is used by rauc
RAUC_SYSTEM_CONF_PATH = "${sysconfdir}/rauc/system.conf"
NAND_RAUC_SYSTEM_CONF_PATH = "${sysconfdir}/rauc/system.conf.nand"
EMMC_RAUC_SYSTEM_CONF_PATH = "${sysconfdir}/rauc/system.conf.mmc"
