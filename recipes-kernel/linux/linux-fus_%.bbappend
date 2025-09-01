FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://rauc.cfg"

do_configure:append () {
    # Ensure config fragment is applied
    if [ -f "${WORKDIR}/rauc.cfg" ]; then
        cat "${WORKDIR}/rauc.cfg" >> "${B}/.config"
    fi
}
