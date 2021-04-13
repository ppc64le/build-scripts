#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : psad
# Version       : 3.0
# Source repo   : https://github.com/mrash/psad
# Tested on     : SLES 12 SP4
# Script License: GPL-2.0 License  
# Maintainer    : Nishikant Thorat <Nishikant.Thorat@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# NOTE		: If running in container, make sure you will have 
#                 "--cap-add=NET_ADMIN" parameter, while creating container
# ----------------------------------------------------------------------------
zypper install -y git wget vim gmake gcc iptables iproute net-tools tar perl-ExtUtils-MakeMaker

wget http://www.cipherdyne.org/modules/IPTables-ChainMgr-1.6.tar.gz
tar -xzf IPTables-ChainMgr-1.6.tar.gz
cd IPTables-ChainMgr-1.6
perl Makefile.PL
make
make install
cd ..
git clone https://github.com/mrash/psad
cd psad
make all
cd test
./test-psad.pl
