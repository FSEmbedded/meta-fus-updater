# Introduction

The layer **meta-fus-updater** is a main component of **FSUP-Framework** integration. The framework based on RAUC and uses different open source libraries to update u-boot, kernel, root file system and application. The framework follows the idea of always having a working configuration.

## Overview - Suppored architecture

| Architecure | Boot Device | Version | State    |
|-------------|-------------|---------|----------|
| fsimx8mp    | eMMC        | >=fsimx8mp-2024.11      | &#10003; |
| fsimx93     |             |         |in work  |
| fsimx8mm    |             | |&#10007; |


## Building images

Clone ***releases-fus*** repository from [F&S GitHub](https://github.com/FSEmbedded) and download configured layers by executing ***setup-yocto*** shell script. Following steps

```shell
git clone https://github.com/FSEmbedded/releases-fus.git
```

Change into cloned directory and checkout needed release.

```shell
cd releases-fus
git checkout fsimx8mp-2024.11
```

Run ***setup-yocto*** shell script to download available layers.

```shell
source setup-yocto build
```

Configure yocto to build F&S images
```shell
cd build/yocto-fus
DISTRO=<distro name> MACHINE=<machine name> . fus-setup-release.sh
```
The distributions ***fus-imx-wayland*** and ***fus-imx-xwayland*** can be used for F&S following machine configurations:

> fsimx6sx fsimx6ul fsimx7ulp fsimx8mm fsimx8mn fsimx8mp

```shell
cd build-<machine name>-<distro name>
bitbake <image name>
```
The layer provides additional image:

| Image name     | Description             |
|----------------|-------------------------|
| fus-image-update-std  | Standard image with fsup framework (Weston) |

## Table of contents

- [Layer Overview](docs/layer-description.md)
- Core Components of FSUP Framework
    - [F&S Updater CLI](docs/fus-updater.md)
    - [Dynamic Overlay](docs/dynamic-overlay.md)
- [Automatic Update from USB Stick](docs/automatic-update.md)
- [Structure of Deploy Directory](docs/deployment-overview.md)
