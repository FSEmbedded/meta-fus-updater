## Dynamic overlay

Dynamic overlay is the part of the FSUP framework that manages the application overlay and
the persistent memory. The command *dynamic_overlay* is started before init.

The *recipes-dynamic_overlay* recipe builds the binary, which is configured to detect
the persistent partition named *data*. The detection works for block devices like eMMC and MTD devices like NAND.

The recipe configures the build to match the FSUP framework layout, and the configuration
can be adapted by the user. The following definitions are available for adaptation.

### Definitions set by the recipe

- **LOG_BACKEND** sets the logging backend. Set to *KMSG*.
- **RAUC_SYSTEM_CONF_PATH** sets the path to the system.conf.
  Set to *${FUS_PERSISTENT_ROOT}/conf/system.conf*.
- **UBOOT_ENV_PATH** sets the path to the configuration file for the bootloader
  tools *fw_printenv* and *fw_setenv*. Set to *${FUS_PERSISTENT_ROOT}/conf/fw_env.config*.
- **PERSISTENT_MEMORY_MOUNTPOINT** sets the mount point of the persistent memory.
  Set to *${FUS_PERSISTENT_ROOT}*.
- **PATH_TO_MOUNT_APPIMAGE** and **DEFAULT_APPLICATION_PATH** set the mount point
  of the active application image. Set to *${FUS_APPLICATION_DIR}/current*.
- **DEFAULT_OVERLAY_PATH** sets the path to the overlay configuration of the application.
  Set to *${FUS_APPLICATION_DIR}/current/overlay.ini*.
- **DEFAULT_UPPERDIR_PATH** and **DEFAULT_WORKDIR_PATH** set the upper and work directory
  of the overlay. Set to *${FUS_PERSISTENT_ROOT}/upperdir* and *${FUS_PERSISTENT_ROOT}/workdir*.
- **APP_IMAGE_DIR** sets the directory that holds the application images.
  Set to *${FUS_APPLICATION_DIR}/*.

*FUS_PERSISTENT_ROOT* defaults to */rw_fs/root* and *FUS_APPLICATION_DIR* to
*${FUS_PERSISTENT_ROOT}/application*, both in *conf/layer.conf*.

### Further definitions

These definitions keep their CMake defaults unless they are overridden in *EXTRA_OECMAKE*.

- **NAND_RAUC_SYSTEM_CONF_PATH** sets the path to the system.conf
  for NAND boot devices. Default value is */etc/rauc/system.conf.nand*.
- **EMMC_RAUC_SYSTEM_CONF_PATH** sets the path to the system.conf
  for eMMC boot devices. Default value is */etc/rauc/system.conf.mmc*.
- **NAND_UBOOT_ENV_PATH** sets the path to the configuration file for the bootloader
  tools *fw_printenv* and *fw_setenv* for NAND boot devices.
  Default value is */etc/fw_env.config.nand*.
- **EMMC_UBOOT_ENV_PATH** sets the path to the configuration file for the bootloader
  tools *fw_printenv* and *fw_setenv* for eMMC boot devices.
  Default value is */etc/fw_env.config.mmc*.
- **PERSISTMEMORY_DEVICE_NAME** sets the name of the persistent partition.
  It must match the name in the layout of the update device.
  Default value is *data*.

### X.509 certificate store

The certificate store on the secure partition (*Secure* on NAND, a raw block range on eMMC)
is only built with *meta-fus-updater-azure*, which also sets its definitions,
including **EMMC_SECURE_PART_BLK_NR**. See the dynamic overlay documentation of that layer.
