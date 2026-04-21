## Automatic update

The firmware, application or common update can be done via USB stick or SD card.
**udev** is used for detection of the update device.

The selected drive must have the label **FUS-UPDATER**. To declare the update files
there is an environment description mandatory.

The file name ***update_config*** must be available and support the following variables:

```shell
UPDATE_FILE=<update image name>
UPDATE_TYPE=<fw|app>         # optional; auto-detected from fsupdate.json if omitted
SCAN_FOR_UPDATE=yes          # optional; scan for *.fs/*.fw/*.app if UPDATE_FILE not set
```

Possible images are *firmware.fs*, *application.fs* or *update.fs*.

After successful installation the script initiates reboot by executing
`fs-updater --apply_update`. On the next boot the mark-good service automatically
calls `fs-updater --commit_update` once the update is confirmed healthy.

### How it works

1. The udev rule detects a block device with label **FUS-UPDATER** and triggers
   `fus-usb-update@.service`, which starts `/usr/libexec/usb_fs_updater.sh`.
2. The script checks `fs-updater --update_reboot_state`. If the state machine is
   not idle (exit code ≠ 27 / `NO_UPDATE_REBOOT_PENDING`), the update is skipped
   to avoid overwriting a pending update from a previous run.
3. The device is mounted read-only. The update file is located via `update_config`
   or by scanning (opt-in via `SCAN_FOR_UPDATE=yes`).
4. If sufficient RAM is available the update file is copied to `/tmp` so the USB
   stick can be removed safely before the update completes.
5. `fs-updater --automatic` is called with `UPDATE_STICK` and `UPDATE_FILE`
   environment variables. On success, `fs-updater --apply_update` reboots into
   the new slot.

### Log file

Log file can be found at `/var/log/fus-updater.log`.
