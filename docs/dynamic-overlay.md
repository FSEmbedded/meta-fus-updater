## Dynamic overlay

Dynamic overlay is a part of FSUP framework to application, application overlay and
persistent memory. The command *dynamic_overlay* would started before init.

The *recipe-dynamic_overlay* creates the binary and configured to detect
persistent partition named *data* and partition for secure data named *secure*. The detection functionality works for block devices like eMMC and mtd devices like NAND.

The recipe configures the build process to integrate
FSUP framework layout and can be adapted by the user.
For adaption process set of definitions is avaialble.

#### Enabled definitions:
- **RAUC_SYSTEM_CONF_PATH** sets path to the system.conf
  default value is */etc/rauc/system.conf*
- **NAND_RAUC_SYSTEM_CONF_PATH** sets path the system.conf
  for boot device NAND. Default value is */etc/rauc/system.conf.nand*
- **EMMC_RAUC_SYSTEM_CONF_PATH** sets path to the system.conf
  for boot device eMMC. Default value is */etc/rauc/system.conf.mmc*
- **UBOOT_ENV_PATH** sets the path to configuration file for bootloader
  fw tools *fw_printenv*, *fw_setenv*. Default value is */etc/fw_env.config*.
- **NAND_UBOOT_ENV_PATH** sets the path to configuration file for bootloader
  fw tools *fw_printenv*, *fw_setenv* boot device NAND.
  Default value is */etc/fw_env.config.nand*.
- **EMMC_UBOOT_ENV_PATH** sets the path to configuration file for bootloader
  fw tools *fw_printenv*, *fw_setenv* boot device NAND.
  Default value is */etc/fw_env.config.mmc*.
- **EMMC_SECURE_PART_BLK_NR** sets start block of secure partition.
  At the time it is a RAW partition. Default value is *16384*

#### Optional definitions
- **PERSISTMEMORY_REGEX_EMMC** is regular expression to detect
  boot device mmc. Default value *root=/dev/mmcblk[0-2]p[0-9]{1,3}*.
- **PERSISTMEMORY_REGEX_NAND** is regular expression to detect
  boot device nand with ubifs. Default value is *root=/dev/ubiblock0_[0-1]*.
- **PERSISTMEMORY_DEVICE_NAME** adds other partition name.
  Must be same name in layout of update device.
  Default value is *data*.
