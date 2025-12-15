#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: collectd
# Version	: collectd-5.12.0
# Source repo	: https://github.com/collectd/collectd.git
# Tested on	: UBI: 8.7
# Language      : C, Perl
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

PACKAGE_NAME=collectd
PACKAGE_VERSION=${1:-collectd-5.12.0}
PACKAGE_URL=https://github.com/collectd/collectd.git
HOME_DIR=${PWD}

yum update -y
yum install -y git wget tar make yum-utils gcc gcc-c++ libcurl libgcrypt-devel libxml2-devel rrdtool python3-devel python3 protobuf-c libpq-devel perl libpcap-devel libmemcached lua autoconf automake libtool pkg-config

#Adding repo to install flex and bison
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y flex flex-devel bison

#Cloning collectd repo
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Building configure file
./build.sh

#Configuring collectd
./configure

if ! make; then
        echo "Build Fails"
	exit 1
elif ! make check; then
        echo "Test Fails"
        exit 2
elif ! make install; then
        echo "Install Fails"
	exit 1
else
        echo "Build, Install and Test Success"
        exit 0
fi