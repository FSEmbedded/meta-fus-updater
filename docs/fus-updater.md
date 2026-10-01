## F&S Updater CLI

One core component of the F&S update framework is the command line interface (CLI).
The tool integrates the RAUC firmware, F&S application and Azure Cloud support.
This gives the user uniform calls for different update types.

In general, the tool arguments are classified into three groups:
- **local usage** - local update process on the board
- **generic usage** - for local and Azure process
- **Azure Cloud** - update process with Azure Cloud

### CLI Arguments

| CLI argument | Type | Description |
|---|---|---|
| `--update_file` | string | Initiates update process and installs update image. Expects absolute path to the image. (generic) |
| `--update_type` | string | Only for a bare update image (RAUC artifact or application image): `"fw"` or `"app"`. Omit it for `.fs` containers; their type is read from fsupdate.json. (generic) |
| `--commit_update` | switch | Commit pending update after successful reboot. (generic) |
| `--rollback_update` | switch | Rollback the last installed update. Allowed after the reboot into the update and before commit. (local) |
| `--switch_fw_slot` | switch | Switch to next stable firmware slot. Run `--apply_update` as a separate call afterwards. (local) |
| `--switch_app_slot` | switch | Switch to next stable application slot. Run `--apply_update` as a separate call afterwards. (local) |
| `--apply_update` | switch | Apply pending update/rollback/switch and initiate reboot. (generic) |
| `--update_reboot_state` | switch | Print current update state from U-Boot environment. (generic) |
| `--firmware_version` | switch | Print current firmware version. (generic) |
| `--application_version` | switch | Print current application version. (generic) |
| `--set_fw_state_bad` | char | Mark firmware state A or B as bad. (local) |
| `--is_fw_state_bad` | char | Check if firmware state A or B is bad. (local) |
| `--set_app_state_bad` | char | Mark application state A or B as bad. (local) |
| `--is_app_state_bad` | char | Check if application state A or B is bad. (local) |
| `--automatic` | switch | Automatic update mode. Reads `UPDATE_STICK`, `UPDATE_FILE` and, for a bare `fw` or `app` image, `UPDATE_TYPE` env vars. (local) |
| `--debug` | switch | Enable debug-level logging. (local) |
| `--version` | switch | Print CLI version. (local) |
| `--is_update_available` | switch | Check if an update is available on the server. (Azure Cloud) |
| `--download_update` | switch | Start download of available update from server. (Azure Cloud) |
| `--download_progress` | switch | Show progress of current download. (Azure Cloud) |
| `--install_update` | switch | Install downloaded update. (Azure Cloud) |

> Note: Argument group *Azure Cloud* can be used only with *meta-fus-updater-azure*.

### Return Codes

Each CLI operation returns a numeric exit code. Codes are grouped by operation type:

| Range | Operation | Codes |
|-------|-----------|-------|
| 0, 4, 8 | Update installed | 0=firmware, 4=application, 8=firmware and application |
| 9-11 | Update failed (every update type) | 9=progress error, 10=internal error, 11=system error |
| 12-15 | Rollback / slot switch | 12=success, 13=progress error, 14=internal error, 15=system error |
| 16-19 | Commit | 16=committed, 17=not needed, 18=invalid U-Boot state, 19=system error |
| 20-33 | Reboot state query | Maps `update_reboot_state` enum to exit code (20-33) |
| 34-37 | Update available (Azure) | 34=none, 35=FW, 36=APP, 37=FW+APP |
| 38-41 | Download (Azure) | 38=no queue, 39=started, 40=already started, 41=failed |
| 42-45 | Download progress (Azure) | 42=not started, 43=waiting, 44=in progress, 45=finished |
| 46-49 | Install (Azure) | 46=no queue, 47=in progress, 48=finished, 49=failed |
| 50-51 | Apply | 50=success, 51=failed |
| 52-54 | Get/set state | 52=success, 53=wrong parameter, 54=state is bad (also: switch refused, target slot is bad) |
| 60-65 | Argument validation | 60=invalid update type, 61=update file not found, 62=environment variable `UPDATE_STICK` not set, 63=environment variable `UPDATE_FILE` not set, 64=`--update_type` without `--update_file`, 65=incompatible argument combination |
| 70 | Reboot | 70=reboot failed |
| 75 | Commit | 75=committed, switch not taken: the running slot stays |
| 124 | Fatal | 124=unhandled exception |

## Update Types

There are three types of updates implemented:
- *firmware update* - contains the kernel, device tree and rootfs
- *application update* - contains the application with additional artifacts
- *common update* - combines firmware and application

Each update type can be installed locally with the command

`fs-updater --update_file <updatefile>`

The CLI detects the update type from an additional configuration file, which
must be part of the update image.
With `FUS_APPLICATION_DEPLOY_MODE = "rootfs"` the build creates only the firmware update.

The update description is based on JSON. For example, **base-fus-updater.bbclass** generates the update description from the *fsupdate-template.json* template.

```text
{
    "name": "Common F&S Update",
    "version": "1.0",
    "images": {
        "updates" : [
            {
                "description": <fw_update_description>,
                "version": <fw_version>,
                "handler": <fw_handler>,
                "file": <fw_name>,
                "hashes": {
                    "sha256": <fw_sha_hash>
                }
            },
            {
                "description": <app_update_description>,
                "version": <app_version>,
                "handler": <app_handler>,
                "file": <app_name>,
                "hashes": {
                    "sha256": <app_sha_hash>
                }
            }
        ]
    }
}
```

### Firmware update

The firmware update name is *firmware_&lt;dev&gt;.fs*, where &lt;dev&gt; is *emmc* or *nand*. The update consists of the RAUC
binary image *update.fw* (*rauc_update_&lt;dev&gt;.artifact*) and the fsupdate.json description.

```json
{
    "name": "Common F&S Update",
    "version": "1.0",
    "images": {
        "updates" : [
            {
                "description": "FUS Firmware Update",
                "version": "20241019",
                "handler": "fus/firmware",
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

The application update name is *application.fs*. The update consists of the application SquashFS container binary update.app and the fsupdate.json description.

```json
{
    "name": "Common F&S Update",
    "version": "1.0",
    "images": {
        "updates" : [
            {
                "description": "FUS Application Update",
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

The common update name is *update_&lt;dev&gt;.fs*. The update consists of the firmware binary *update.fw*, the application binary *update.app* and the *fsupdate.json* description.

```json
{
    "name": "Common F&S Update",
    "version": "1.0",
    "images": {
        "updates" : [
            {
                "description": "FUS Firmware Update",
                "version": "20241019",
                "handler": "fus/firmware",
                "file": "update.fw",
                "hashes": {
                    "sha256": "bef24ea978b3a0b171f673cafc585151f637f2231fd06732b77435b44cbf9058"
                }
            },
            {
                "description": "FUS Application Update",
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

## Recipe fs-updater-cli

fs-updater-cli installs an additional bash completion script to the
*/etc/bash_completion.d/* directory. The script name is fs_updater. It can be sourced with
`. /etc/bash_completion.d/fs_updater`.

For more information, see the recipe of the package [fs-updater-cli](../recipes-fs-updater-module/fs-updater-cli/fs-updater-cli.bb).
