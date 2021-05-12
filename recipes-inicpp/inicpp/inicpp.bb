inherit cmake

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
DESCRIPTION = "inicpp (C++ parser of INI files with schema validation)"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=7b17e5f89008916a36fff249ec27716d"
BBCLASSEXTEND = "nativesdk"
ALLOW_EMPTY_${PN} = "1"
SRCREV = "1a3ac414f9ccd7ed5d5c0810206d336afd0f36ba"
SRC_URI = "git://github.com/SemaiCZE/inicpp.git \
		   file://0001-extend-allowed-characters.patch \
"

EXTRA_OECMAKE += "	-DINICPP_BUILD_SHARED=off \
					-DINICPP_BUILD_TESTS=off \
					-DINICPP_BUILD_EXAMPLES=off \
				 "
S = "${WORKDIR}/git"

#PACKAGES = "${PN}"

FILES_${PN} = " \
	${libdir} \
	${libdir}/libinicpp.a \
	${includedir}/inicpp \
	${includedir}/inicpp/string_utils.h \
	${includedir}/inicpp/dll.h \
	${includedir}/inicpp/schema.h \
	${includedir}/inicpp/parser.h \
	${includedir}/inicpp/option.h \
	${includedir}/inicpp/section.h \
	${includedir}/inicpp/types.h \
	${includedir}/inicpp/config.h \
	${includedir}/inicpp/option_schema.h \
	${includedir}/inicpp/inicpp.h \
	${includedir}/inicpp/exception.h \
	${includedir}/inicpp/section_schema.h \
"
#INSANE_SKIP_${PN} = "installed-vs-shipped staticdev"

do_install() {
	install -d ${D}/${includedir}/inicpp
	install -d ${D}/${libdir}/

	install -m 0755 ${S}/include/inicpp/inicpp.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/dll.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/string_utils.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/schema.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/parser.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/option.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/section.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/types.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/config.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/option_schema.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/inicpp.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/exception.h ${D}/${includedir}/inicpp
	install -m 0755 ${S}/include/inicpp/section_schema.h ${D}/${includedir}/inicpp

	install -m 0755 ${B}/libinicpp.a ${D}/${libdir}
}
