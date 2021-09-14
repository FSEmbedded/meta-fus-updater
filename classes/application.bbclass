do_prepare_application_directory() {
	if [ -d ${D}/app ]; then
		bbfatal "Folder: app/ is not allowed to use. It is reserverd for the application folder"
	fi;

	rm -rf ${WORKDIR}/app
	mv ${D} ${WORKDIR}/app
	mkdir -p ${D}/app
	mv ${WORKDIR}/app ${D}
}

#addtask do_prepare_application_directory after do_install before do_package
do_package[prefuncs] += "do_prepare_application_directory "

FILES_${PN} = "app/* "
