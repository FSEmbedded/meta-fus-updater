LICENSE = "CLOSED"
SRC_URI = "\
	file://CMakeLists.txt \
	file://main.cpp \
	file://start_application.service \
"
S="${WORKDIR}"

REQUIRED_DISTRO_FEATURES = "systemd"

inherit cmake application


do_install_append() {

	install -d ${D}${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/start_application.service ${D}${systemd_system_unitdir}
	touch ${D}${systemd_system_unitdir}/test
	install -d ${D}/etc/systemd/system/multi-user.target.wants
	ln -s ${systemd_system_unitdir}/start_application.service ${D}/etc/systemd/system/multi-user.target.wants/start_application.service
}