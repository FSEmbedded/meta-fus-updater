## Automatic update

The firmware, application or common update can be installed from a USB stick or an SD card.
**udev** is used to detect the update device.

The selected drive must have a partition with the label **FUS-UPDATER**. The update files are declared
in a mandatory environment description.

The file ***update_config*** must be available and supports the following variables:

```shell
UPDATE_FILE=<update image name>
UPDATE_TYPE=<fw|app>         # optional; with SCAN_FOR_UPDATE, scan for *.fw/*.app instead of *.fs
SCAN_FOR_UPDATE=yes          # optional; scan for an update file if UPDATE_FILE is not set or not found
```

Possible images are *firmware_&lt;dev&gt;.fs*, *application.fs* or *update_&lt;dev&gt;.fs*, where &lt;dev&gt; is *emmc* or *nand*.

After a successful installation the script initiates a reboot by executing
`fs-updater --apply_update`. After the reboot the update must be committed
explicitly with `fs-updater --commit_update`, e.g. by the application once it
runs correctly. The mark-good service does not do this: it is skipped while an
update is pending.

### How it works

1. The udev rule detects a partition with the label **FUS-UPDATER** and triggers
   `fus-usb-update@.service`, which starts `/usr/libexec/usb_fs_updater.sh`.
2. The script checks `fs-updater --update_reboot_state`. If the state machine is
   not idle (exit code ≠ 27 / `NO_UPDATE_REBOOT_PENDING`), the update is skipped
   to avoid overwriting a pending update from a previous run.
3. The device is mounted read-only. The update file is located via `update_config`
   or by scanning (opt-in via `SCAN_FOR_UPDATE=yes`).
4. If sufficient RAM is available, the update file is copied to `/tmp` so the USB
   stick can be removed safely before the update completes.
5. `fs-updater --automatic` is called with `UPDATE_STICK` and `UPDATE_FILE`
   environment variables. On success, `fs-updater --apply_update` reboots into
   the new slot.

### Log file

The log file can be found at `/var/log/fus-updater.log`.
