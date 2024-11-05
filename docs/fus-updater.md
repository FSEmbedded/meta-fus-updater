## F&S Updater CLI
One core component of F&S update framework is command line interface (CLI).
The tool integrates the RAUC firmware, F&S application and Azure Cloud support.
This allows the user uniform calls for different update types.

In general the tool arguments are classified in 3 groups
- **local usage** - local update process on the board
- **generic usage** - for local and azure process
- **azure cloud** - update process with Azure Cloud

Following parameter are available

| CLI argument        | Description             |
|---------------------|-------------------------|
| is_fw_state_bad     | Check firmware state for bad. Accepted states: A or B (local usage) |
| set_fw_state_bad    | Mark firmware A or B bad. Accepted states: A or B (local usage) |
| is_app_state_bad    | Check application state for bad. Accepted states: A or B (local usage) |
| is_app_state_bad    | set_app_state_bad Mark application A or B bad. Accepted states: A or B (local usage) |
| is_update_available | Checks if an update is available on the server (Arzure Cloud) |
| download_update     | Starts download of the available update from the server (Azure Cloud). Needs usage of command is_update_available. |
| download_progress   | Shows the progress of the current update (Azure Cloud). Can be used during down load to get progress state.
| install_update      | Installs downloaded update (Azure Cloud). Need usage of command download_update with finished state.
| apply_update        | Updates ‘update’ state and initiate switch to the installed version (generic usage)
| version             | Prints CLI version (local usage) |
| application_version | Prints current application version (generic usage) |
| firmware_version    | Prints current firmware version (generic usage) |
| debug               | Enables additional messages in debug mode (local usage) |
| automatic           | Automatic update mode. Allows automatic update from usb stick (local usage)
| update_reboot_state | Gets state of environment update (generic usage) |
| commit_update       | Runs after boot and waits for application response (generic usage) |
| switch_app_slot     | Switch to next stable application slot. (local usage) |
| switch_fw_slot      | Switch to next stable firmware slot. (local usage) |
| rollback_update     | Rollback of the last installed update. Start before update commit necessary. (local usage) |
| update_file         | Initiates update process and installs update image. Expects absolute path to the image. (generic usage) |
| --, --ignore_rest   | Ignores the rest of the labeled arguments following this flag (local usage) |

Each argument returns differnt state. All error state are described in our **FS Update Framework** documentation.

> Note: Argument group *Azure Cloud* can be used only with *meta-fus-updater-azure*.

## Update Types

There are three types of updates implemented:
- *firmware update* - inherits kernel, device tree and rootfs
- *application update* - inherits application with additional artifacts 
- *common update* - combines firmware and application

Each update type can be install localy by command

`fs-updater --update_file <updatefile>`

The CLI detects update type by additional configuration file, which
must be a part of update image.

The update description is based on json. E.g. **base-fus-updater.bbclass** generates update description from *fsupdate.json* template.

```json
{
    "name": "Common F&S Update",
    "version": "1.0",
    "images": {
        "updates" : [
            {
                "description": <fw_update_description>,
                "version": <fw_version>,
                "handler": <fw_handler>,
                "file": "update.fw",
                "hashes": {
                    "sha256": <fw_sha_hash>
                }
            },
            {
                "description": <app_update_description>,
                "version": <app_version>,
                "handler": <app_handler>,
                "file": "update.app",
                "hashes": {
                    "sha256": <app_sha_hash>
                }
            }
        ]
    }
}
```
### Firmware update

The firmware update name is *firmware.fs*. The update consists of the RAUC
binary image *update.fw* (*rauc_update_[emmc|nand].artifact*) and fsupdate.json description.

```json
{
    "name": "Common F&S Update",
    "version": "1.0",
    "images": {
        "updates" : [
            {
                "description": "FUS Firmware Update",
                "version": "20241019",
                "handler": "fus/firwmware",
                "file": "update.fw",
                "hashes": {
                    "sha256": "bef24ea978b3a0b171f673cafc585151f637f2231fd06732b77435b44cbf9058"
                }
            }
        ]
    }
}
```

### Application update

Application update name is *application.fs*. The update consists of the application squashfs container binary update.app and fsupdate.json descripction.

```json
{
    "name": "Common F&S Update",
    "version": "1.0",
    "images": {
        "updates" : [
            {
                "description": "FUS Firmware Update",
                "version": "20241019",
                "handler": "fus/application",
                "file": "update.app",
                "hashes": {
                    "sha256": "18d6336fcf6339d8a583a68a41c15361b7a44e762319bf04814779c5e0dac504"
                }
            }
        ]
    }
}
```

### Common update

The common update name is *update.fs*. The update consists of the firmware binary *update.fw*, application binary *update.app* and *fsupdate.json* description.
```json
{
    "name": "Common F&S Update",
    "version": "1.0",
    "images": {
        "updates" : [
            {
                "description": "FUS Firmware Update",
                "version": "20241019",
                "handler": "fus/firwmware",
                "file": "update.fw",
                "hashes": {
                    "sha256": "bef24ea978b3a0b171f673cafc585151f637f2231fd06732b77435b44cbf9058"
                }
            },
            {
                "description": "FUS Firmware Update",
                "version": "20241019",
                "handler": "fus/application",
                "file": "update.app",
                "hashes": {
                    "sha256": "18d6336fcf6339d8a583a68a41c15361b7a44e762319bf04814779c5e0dac504"
                }
            }
        ]
    }
}
```
## Recipe fs-update-module

fs-updater-cli installs additional bash completion script to
*/etc/bash_completion.d/* directory. The script name is fs_updater. The script can be started by command
`. /etc/bash_completion.d/fs_updater`.

Fore more information see recipe implementation of package [fs-updater-cli](/recipes-fs-updater-module/fs-updater-cli/fs-updater-cli.bb)