#!/bin/bash -e
# -----------------------------------------------------------------------------
#  b46c278df98f
# Package       : csync2
# Version       : master
# Source repo   : https://github.com/LINBIT/csync2.git
# Tested on     : UBI 8.5
# Language      : C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

PACKAGE_NAME=csync2
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/LINBIT/csync2.git

#install required packages
yum install -y git make gcc-c++ wget yum-utils apr-devel perl openssl-devel automake autoconf libtool 

yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
	
yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/
yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/
yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

#install gnutl
yum install -y gnutls-devel.ppc64le gnutls-c++.ppc64le gnutls.ppc64le byacc.ppc64le flex-devel.ppc64le flex.ppc64le \
libffi libffi-devel sqlite sqlite-devel sqlite-libs freeradius-sqlite.ppc64le perl-DBD-SQLite.ppc64le \
mysql-devel librsync-devel ncurses-devel libacl-devel readline-devel.ppc64le readline.ppc64le

#clone the package

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test the package.
./autogen.sh
./configure
make && make install
make check
