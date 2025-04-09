#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : numba
# Version       : 0.57.0
# Source repo   : https://github.com/numba/numba.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Robin Jain <robin.jain1@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_VERSION=${1:-"0.57.0"}
PACKAGE_NAME=numba
PACKAGE_URL=https://github.com/numba/numba

# Install dependencies and tools.
yum install -y git gcc gcc-c++ make wget python-devel xz-devel bzip2-devel openssl-devel zlib-devel libffi-devel

# Add repositories and Import GPG key
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

# Install EPEL repository
dnf install -y --nodocs https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

#install pytest
pip install pytest

# Install llvm14 and set llvm-config path
yum install -y llvm14-devel.ppc64le
export PATH=$PATH:/usr/lib64/llvm14/bin

# Install numpy
pip install numpy==1.21.1

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install -r requirements.txt 
python3 setup.py build_ext --inplace 

# Install
if !(python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Install_Success"
    exit 0
fi

# Skipping the test cases as they are taking more than 5 hours. 
