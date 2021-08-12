SUMMARY = "FS update Framework library"
SECTION = "libs"
LICENSE = "CLOSED"

S = "${WORKDIR}/fs_updater_lib"

DEPENDS = " \
	libubootenv \
	botan \
	jsoncpp \
	zlib \
	inicpp \
"

RDEPENDS_${PN} = " \
	botan \
"

SRC_URI = "file://fs_updater_lib.tar.gz"

inherit cmake

EXTRA_OECMAKE += "-DBOTAN2:STRING=${STAGING_DIR_TARGET}/usr/include/botan-2/"
