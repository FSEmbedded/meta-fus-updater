# $1 workdir of the caller script
# $2 wordkri of the called scriüt
#

sh $2/rauc-download

echo "BBLAYERS += \" \${BSPDIR}/sources/meta-rauc \"" >> $BUILD_DIR/conf/bblayers.conf
echo "BBLAYERS += \" \${BSPDIR}/sources/meta-fus-updater \"" >> $BUILD_DIR/conf/bblayers.conf
