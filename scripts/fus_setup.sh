# $1 workdir of the caller script
# $2 workdir of the called script
#
FORMER_PWD=$PWD
cd $1/..
sh $2/rauc-download

cd $FORMER_PWD

echo "BBLAYERS += \" \${BSPDIR}/sources/meta-rauc \"" >> $BUILD_DIR/conf/bblayers.conf
echo "BBLAYERS += \" \${BSPDIR}/sources/meta-fus-updater \"" >> $BUILD_DIR/conf/bblayers.conf
