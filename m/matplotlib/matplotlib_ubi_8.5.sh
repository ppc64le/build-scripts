#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package	    : matplotlib
# Version	    : v3.4.1
# Source repo	: https://github.com/matplotlib/matplotlib.git
# Tested on	    : UBI: 8.5
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Sachin Kakatkar<Sachin.Kakatkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the sript ./matplotlib_ubi_8.5.sh v3.4.1(version to test)
PACKAGE_NAME=matplotlib
PACKAGE_VERSION=${1:-v3.4.1}
PACKAGE_URL=https://github.com/matplotlib/matplotlib.git

dnf install git gcc-c++ make cmake openblas python38 python38-devel zlib-devel libjpeg-devel gcc-gfortran libarchive -y
pip3.8 install tox numpy pytest cycler kiwisolver cppy pillow python-dateutil webp

OS_NAME=`python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])"`

rm -rf $PACKAGE_NAME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply test_subfigure_ss_fix.patch
if ! tox; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail |  Install_success_but_test_Fails"
	exit 0
else
	echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME "
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi

#Result parity with intel
