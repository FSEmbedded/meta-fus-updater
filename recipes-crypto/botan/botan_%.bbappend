PV = "2.18.1"
SRC_URI = "https://botan.randombit.net/releases/Botan-${PV}.tar.xz"
SRC_URI[md5sum] = "77c558179f276273e0bf39ef941d36c5"
SRC_URI[sha256sum] = "f8c7b46222a857168a754a5cc329bb780504122b270018dda5304c98db28ae29"
LIC_FILES_CHKSUM = "file://license.txt;md5=a02e03c8fa2c5e7b9b3fcc1b9811fd3b"

DISABLE_STATIC = ""
DEPENDS += " sed-native \
"
do_configure() {
	python3 ${S}/configure.py \
	--prefix="${D}${prefix}" \
	--cpu="${CPU}" \
	--cc-bin="${CXX}" \
	--cxxflags="${CXXFLAGS}" \
	--ldflags="${LDFLAGS}" \
	--with-endian=${@oe.utils.conditional('SITEINFO_ENDIANNESS', 'le', 'little', 'big', d)} \
	${@bb.utils.contains("TUNE_FEATURES","neon","","--disable-neon",d)} \
	--with-sysroot-dir=${STAGING_DIR_TARGET} \
	--with-build-dir="${B}" \
	--optimize-for-size \
	--build-targets=static,shared,cli \
	--with-stack-protector \
	--with-python-versions=3 \
	${EXTRA_OECONF}
}

