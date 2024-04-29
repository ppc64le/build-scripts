#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package           : python-openstackclient
# Version           : 6.5.0
# Source repo       : https://github.com/openstack/python-openstackclient
# Tested on         : UBI 8.7
# Language          : Python
# Travis-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=python-openstackclient
PACKAGE_VERSION=${1:-6.5.0}
PACKAGE_URL=https://github.com/openstack/python-openstackclient

yum update -y --allowerasing
yum install -y --allowerasing gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget
yum install -y redhat-rpm-config gcc libffi-devel openssl-devel cargo python39 python39-devel python39-cryptography git

yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/
yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/
yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/

wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3.9 -m pip install --upgrade pip setuptools
python3.9 -m pip install -r requirements.txt
python3.9 -m pip install -r test-requirements.txt
python3.9 -m pip install -e .
python3.9 -m pip install tox wheel --ignore-installed

if ! python3.9 setup.py install ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python3.9 -m tox -e py3 ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
