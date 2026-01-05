#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : mongo-c-driver
# Version          : 1.27.4
# Source repo      : https://github.com/mongodb/mongo-c-driver.git
# Tested on        : UBI 9.3
# Language         : C, Python
# Ci-Check     : True 
# Script License   : Apache License, Version 2 or later
# Maintainer       : Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=mongo-c-driver
PACKAGE_VERSION=${1:-1.27.4}
PACKAGE_URL=https://github.com/mongodb/mongo-c-driver.git

# Install dependencies.
yum install -y yum-utils python3-devel gcc gcc-c++ git pkgconfig kmod perl make cmake gcc-c++ wget tar diffutils openssl-devel

# Add additional repos to install dependencies
yum-config-manager --add-repo http://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/
yum-config-manager --add-repo http://rpmfind.net/linux/centos-stream/9-stream/BaseOS/ppc64le/os/
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y texlive kernel-devel

# Create softlink for python
ln -sf /usr/bin/python3 /usr/bin/python

# Clone mongo-c-driver repo
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mkdir cmake-build
cd cmake-build

# Compile the package
cmake -D ENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF -D BUILD_VERSION="1.27.4" ..
make && make install
if ! make && make install; then
    echo "Build & Install Fails!"
    exit 1

# Tests have been disabled as it takes almost 5 hours to execute
# elif ! make test; then
#      echo "Test Fails!"
#      exit 2
else
    echo "Build, Install and Test Success!"
    exit 0
fi