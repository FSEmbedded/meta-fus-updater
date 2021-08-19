SUMMARY = "FS update Framework cli"
LICENSE = "CLOSED"

S = "${WORKDIR}/fs_updater_cli"

DEPENDS = " \
	libubootenv \
	botan \
	jsoncpp \
	zlib \
	inicpp \
	fs-updater-lib \
	tclap \
"

SRC_URI = "file://fs_updater_cli.tar.gz"

inherit cmake
