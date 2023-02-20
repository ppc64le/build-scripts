#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: opentelemetry-python-contrib
# Version	: 7c75b386
# Source repo	: https://github.com/open-telemetry/opentelemetry-python-contrib
# Tested on	: rhel 8.3
# Language      : python
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
#note: grpc test suite fails inside the container and passes on VM
# ----------------------------------------------------------------------------

PACKAGE_NAME="opentelemetry-python-contrib"
PACKAGE_VERSION=${1:-"7c75b386"}
PACKAGE_URL="https://github.com/open-telemetry/opentelemetry-python-contrib"
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR=$PWD

echo "insstalling dependencies from system repo..."

dnf install -qy http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm
dnf install -qy http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm
dnf config-manager --enable powertools
dnf install -qy epel-release
dnf install -qy git python39-devel cargo rust make sqlite-devel gnutls-devel patch file diffutils zlib-devel libxml2-devel openssl-devel libssh-devel gettext-devel automake libtool m4 atlas-devel lapack-devel blas-devel libpq-devel snappy-devel curl-devel gcc-c++ redis
update-alternatives --set python /usr/bin/python3.9
update-alternatives --set python3 /usr/bin/python3.9

echo "cloning..."
if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd $PACKAGE_NAME
git checkout "$PACKAGE_VERSION"
python3.9 -m venv ~/py39
source ~/py39/bin/activate
pip install -U tox-factor
if ! ./scripts/build.sh; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! tox -f py39; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
