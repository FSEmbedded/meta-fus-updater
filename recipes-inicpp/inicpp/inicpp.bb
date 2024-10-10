inherit cmake lib_package

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
DESCRIPTION = "inicpp (C++ parser of INI files with schema validation)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=7b17e5f89008916a36fff249ec27716d"

ALLOW_EMPTY:${PN} = "1"
SRCREV = "18701e701776f76120a260da2c5e552840a476c4"
SRC_URI = "git://github.com/SemaiCZE/inicpp.git;branch=master;protocol=https \
           file://0001-extend-allowed-characters.patch \
          "

EXTRA_OECMAKE += "	-DINICPP_BUILD_TESTS=off \
					-DINICPP_BUILD_EXAMPLES=off \
				 "
S = "${WORKDIR}/git"

# Means to build the static version
EXTRA_OECMAKE = " -DINICPP_BUILD_SHARED=off"
