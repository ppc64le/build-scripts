#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package	    : apache beam
# Version	    : v2.33.0
# Source repo	: https://github.com/apache/beam.git
# Tested on	    : UBI 8.5
# Language      : go
# Travis-Check  : True
# Script License: Apache License, Version 2 or later and PSF
# Maintainer	: Sachin Kakatkar<Sachin.Kakatkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the sript ./apache_beam_go_ubi_8.5.sh v2.33.0(version to test)
PACKAGE_NAME=beam
PACKAGE_VERSION=${1:-v2.33.0}
GO_VERSION=1.18.1
PACKAGE_URL=https://github.com/apache/beam.git
dnf install git java wget gcc-c++ make cmake openblas python38 python38-devel zlib-devel libjpeg-devel gcc-gfortran libarchive -y
mkdir -p /home/tester/output
cd /home/tester
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf /home/tester/go && tar -C /home/tester -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export  GO111MODULE=on

OS_NAME=`python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])"`

rm -rf $PACKAGE_NAME
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

./local-env-setup.sh
if ! ./gradlew :sdks:go:examples:wordCount; then
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

