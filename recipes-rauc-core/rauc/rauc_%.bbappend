FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " \
  file://rauc-mark-good.service \
  file://rauc-mark-good.init \
  file://check-fsup-state.sh \
"

do_install:append() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/check-fsup-state.sh ${D}${bindir}/

    sed -i -e 's!@SBINDIR@!${sbindir}!g' -e 's!@BINDIR@!${bindir}!g' ${D}${systemd_unitdir}/system/*.service
}

FILES:append:${PN}-mark-good = " ${bindir}/check-fsup-state.sh"
