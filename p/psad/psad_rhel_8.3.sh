#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : psad
# Version       : 3.0
# Source repo   : https://github.com/mrash/psad
# Tested on     : UBI 8.3, RHEL 8.3
# Script License: Apache 2.0
# Maintainer    : Nishikant Thorat <Nishikant.Thorat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
yum install -y git wget vim make gcc initscripts chkconfig iptables iproute net-tools  ruby-devel gcc make rpm-build rubygems
gem install --no-document fpm
# Install iptable perl package
wget http://www.cipherdyne.org/modules/IPTables-ChainMgr-1.6.tar.gz
tar -xzf IPTables-ChainMgr-1.6.tar.gz
cd IPTables-ChainMgr-1.6
perl Makefile.PL
yum install -y  perl-ExtUtils-MakeMaker
make
make install
cd ..
# Install cpan and Date perl package using cpan
yum install -y cpan
export PERL_MM_USE_DEFAULT=1; cpan Date::Calc 

git clone https://github.com/mrash/psad
cd psad
make all 
cd test 
./test-psad.pl
rm -rf psad-install/var/log/psad/*
# This will generate RPM, and will copy RPM to parent directory of build script
fpm -s dir -t rpm -C psad-install/ --version  $(cat ../VERSION) -n psad
mv psad*.rpm ../../
