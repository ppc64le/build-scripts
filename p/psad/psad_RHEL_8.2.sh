#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : psad
# Version       : 3.0
# Source repo   : https://github.com/mrash/psad
# Tested on     : RHEL 8.2
# Script License: Apache 2.0
# Maintainer    : Nishikant Thorat <Nishikant.Thorat@ibm.com>
#
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
# ----------------------------------------------------------------------------
yum install -y git wget vim make gcc initscripts chkconfig iptables iproute net-tools  ruby-devel gcc make rpm-build rubygems whois
gem install --no-document --bindir=/usr/local/bin  fpm
#sudo gem install --no-document fpm
# Install cpan and Date perl package using cpan
yum install -y cpan
export PERL_MM_USE_DEFAULT=1; cpan Date::Calc IPTables::Parse NetAddr::IP Unix::Syslog IPTables::ChainMgr
wget http://www.cipherdyne.org/modules/IPTables-ChainMgr-1.6.tar.gz
tar -xzf IPTables-ChainMgr-1.6.tar.gz
cd IPTables-ChainMgr-1.6
perl Makefile.PL
yum install -y  perl-ExtUtils-MakeMaker
make
make install
cd ..
#
# Build and generate rpm.(Test execution is required as test suite helps to create directory structure for "fpm")
#
git clone https://github.com/mrash/psad
cd psad
make all 
cd test 
./test-psad.pl
rm -rf psad-install/var/log/psad/*
sed -i 's/^INSTALL_ROOT.*/INSTALL_ROOT  \/;/'  psad-install/etc/psad/psad.conf
# This will generate RPM, and will copy RPM to parent directory of build script
cp ../init-scripts/psad-init.redhat psad-install/etc/init.d/psad
export PATH=$HOME/bin:/usr/local/bin:$PATH
fpm -s dir -t rpm -C psad-install/ --version  $(cat ../VERSION) -n psad
mv psad*.rpm ../../
