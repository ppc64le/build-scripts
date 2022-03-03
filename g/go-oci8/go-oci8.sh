# -----------------------------------------------------------------------------
#
# Package	: go-oci8
# Version	: v0.0.7
# Source repo	: https://github.com/mattn/go-oci8
# Tested on	: UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/mattn/go-oci8
PACKAGE_VERSION=${1:-v0.0.7}

set -e

yum install -y git gcc-c++ golang libaio libnsl2 unzip wget
ln -s /usr/lib64/libnsl.so.2 /usr/lib64/libnsl.so.1

# Install Oracle Instantclient needed for tests
mkdir -p /opt/oracle && cd /opt/oracle
wget https://download.oracle.com/otn_software/linux/instantclient/193/instantclient-basic-linux.leppc64.c64-19.3.0.0.0dbru.zip
unzip instantclient-basic-linux.leppc64.c64-19.3.0.0.0dbru.zip
rm -f instantclient-basic-linux.leppc64.c64-19.3.0.0.0dbru.zip
wget https://download.oracle.com/otn_software/linux/instantclient/193/instantclient-sdk-linux.leppc64.c64-19.3.0.0.0dbru.zip
unzip instantclient-sdk-linux.leppc64.c64-19.3.0.0.0dbru.zip
rm -f instantclient-sdk-linux.leppc64.c64-19.3.0.0.0dbru.zip
echo /opt/oracle/instantclient_19_3 > /etc/ld.so.conf.d/oracle-instantclient.conf
ldconfig

# Create configuration file
echo "prefix=/opt/oracle/instantclient_19_3" >> /usr/share/pkgconfig/oci8.pc
echo "exec_prefix=\${prefix}" >> /usr/share/pkgconfig/oci8.pc
echo "libdir=\${prefix}" >> /usr/share/pkgconfig/oci8.pc
echo "includedir=\${prefix}/sdk/include" >> /usr/share/pkgconfig/oci8.pc
echo "glib_genmarshal=glib-genmarshal" >> /usr/share/pkgconfig/oci8.pc
echo "gobject_query=gobject-query" >> /usr/share/pkgconfig/oci8.pc
echo "glib_mkenums=glib-mkenums" >> /usr/share/pkgconfig/oci8.pc
echo "Name: oci8" >> /usr/share/pkgconfig/oci8.pc
echo "Description: oci8 library" >> /usr/share/pkgconfig/oci8.pc
echo "Libs: -L\${libdir} -lclntsh" >> /usr/share/pkgconfig/oci8.pc
echo "Cflags: -I\${includedir}" >> /usr/share/pkgconfig/oci8.pc
echo "Version: 19.3" >> /usr/share/pkgconfig/oci8.pc


OS_NAME=`cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2 | tr -d '"'`

if ! go get -d -t $PACKAGE_NAME@$PACKAGE_VERSION; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 0
fi

cd ~/go/pkg/mod/$PACKAGE_NAME*
if ! go test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Install_success_but_test_Fails"
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME" 
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
