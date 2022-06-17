#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : Zabbix
# Version       : 6e90007
# Source repo   : https://github.com/zabbix/zabbix.git
# Tested on     : UBI 8.5
# Language      : PHP, C
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=zabbix
PACKAGE_VERSION=${1:-6e90007}
PACKAGE_URL=https://github.com/zabbix/zabbix.git

yum update -y
curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm     && dnf install -y epel-release-latest-8.noarch.rpm     && rm -f epel-release-latest-8.noarch.rpm

yum install -y wget yum-utils
yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/virt/ppc64le/ovirt-44/
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Virtualization && mv RPM-GPG-KEY-CentOS-SIG-Virtualization /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization
yum install -y initscripts httpd tar wget curl vim gcc make net-snmp php-mysqlnd  git httpd php libcurl-devel libxml2-devel php-xml php-gd php-bcmath php-mbstring php-ldap php-json libevent-devel pcre-devel cmake policycoreutils-python-utils automake pkgconfig gcc-c++ autoconf automake libtool procps yum-utils libcmocka-devel libyaml-devel perl-YAML-LibYAML libpath_utils-devel perl-IPC-Run3 perl-Path-Tiny mariadb-devel libxml2-devel net-snmp-devel OpenIPMI-devel libevent-devel libcurl-devel pcre-devel

mkdir -p /home/tester/output
cd /home/tester
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 0
fi

cd $PACKAGE_NAME

echo " --------------------------------- checkout version  $PACKAGE_VERSION ------------------------------------"
git checkout $PACKAGE_VERSION

./bootstrap.sh tests
./configure --enable-server --enable-agent --with-mysql --enable-ipv6 --with-net-snmp --with-libcurl --with-libxml2 --with-openipmi
make
make install


echo "------------------Test the package---------------------"
if ! make tests; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi
