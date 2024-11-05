## Automatic update

The firmware, application or common update can be done via USB stick or SD card.
For detection of update device **udev** is using.

The selected drive must have the label **FUS-UPDATER**. To declare the update files
there is an environment description mandatory.

The file name ***update_config*** must be availabe and expect following variable:

```shell
export UPDATE_FILE=<update image name>
```

Possible images are *firmware.fs*, *application.fs* or *update.fs*.

After successful installation the script initiate reboot by
execute command `fs-updater --apply_update`. After booting into updated state
`fs-updater --commit_update` is required and must be done by the user.

### How it's work

After the stick has been inserted and it has been checked that the stick is marked correctly, the */usr/libexec/usb_fs_updater.sh* script is started if successful.

### Log file

Log file *updatestate.log* can be found in */tmp* directory.