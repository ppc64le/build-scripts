#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: erlang-otp
# Version	: OTP-25.3
# Source repo	: https://github.com/erlang/otp.git
# Tested on	: UBI: 8.5
# Language      : Erlang,C++,C
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=erlang-otp
PACKAGE_VERSION=${1:-OTP-25.3}
PACKAGE_URL=https://github.com/erlang/otp.git
HOME_DIR=${PWD}

yum update -y
yum install -y yum-utils autoconf gawk gcc gcc-c++ gzip libxml2-devel libxslt ncurses-devel openssl-devel make tar unixODBC-devel wget git

#Adding repo to install flex
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y flex flex-devel

#Cloning Erlang repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd otp
git checkout $PACKAGE_VERSION

export ERL_TOP=${PWD}

#Configuring Erlang
./configure

export LANG=C

#Building & Installing Erlang
if ! make; then
	echo "Build Fails"
	exit 1
elif ! make install; then
        echo "Install Fails"
	exit 1
else
	echo "Build and Install Success"
fi

#Testing Erlang
#Build and release the test suites
make release_tests
cd release/tests/test_server

if ! $ERL_TOP/bin/erl -s ts install -s ts smoke_test batch -s init stop; then
    echo "Test Fails"
	exit 2
else
    echo "Test Success"
	exit 0
fi
