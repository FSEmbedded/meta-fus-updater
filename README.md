# Introduction

The layer **meta-fus-updater** is the main component of the **FSUP framework** integration. The framework is based on RAUC and uses different open source libraries to update U-Boot, the kernel, the root file system and the application. The framework follows the idea of always having a working configuration.

## Overview - Supported architecture

| Architecture | Boot Device | Version              | State    |
|--------------|-------------|----------------------|----------|
| fsimx8mp     | eMMC        | >=fsimx8mp-2024.11   | &#10003; |
| fsimx93      | eMMC        | >=fsimx93-2025.08    | &#10003; |
| fsimx8mm     | eMMC        | >=fsimx8mm-Y2026.04  | &#10003; |
| fsimx8mn     |             |                      | &#10007; |

## Building images

Clone the ***releases-fus*** repository from [F&S GitHub](https://github.com/FSEmbedded) and download the configured layers by executing the ***setup-yocto*** shell script:

```shell
git clone https://github.com/FSEmbedded/releases-fus.git
```

Change into the cloned directory and check out the needed release.

```shell
cd releases-fus
git checkout fsimx93-2025.08
```

Run the ***setup-yocto*** shell script to download the available layers.

```shell
source setup-yocto build
```

Configure Yocto to build F&S images:

```shell
cd build/yocto-fus
DISTRO=<distro name> MACHINE=<machine name> . fus-setup-release.sh
```
The distributions ***fus-imx-wayland*** and ***fus-imx-xwayland*** can be used for the following F&S machine configurations:

> fsimx6sx fsimx6ul fsimx7ulp fsimx8mm fsimx8mn fsimx8mp fsimx93

```shell
cd build-<machine name>-<distro name>
bitbake <image name>
```

The layer provides an additional image:

| Image name     | Description             |
|----------------|-------------------------|
| fus-image-update-std  | Standard image with FSUP framework (Weston) |

## Table of contents

- [Layer Overview](docs/layer-description.md)
- Core Components of FSUP Framework
    - [F&S Updater CLI](docs/fus-updater.md)
    - [Dynamic Overlay](docs/dynamic-overlay.md)
- [Automatic Update from USB Stick](docs/automatic-update.md)
- [Structure of Deploy Directory](docs/deployment-overview.md)
- [Certificates and Signing](docs/certificates.md)
