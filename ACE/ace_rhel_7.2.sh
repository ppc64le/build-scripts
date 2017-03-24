# ----------------------------------------------------------------------------
#
# Package	: ACE
# Version	: 6.4.2
# Source repo	: https://github.com/DOCGroup/ATCD.git
# Tested on	: rhel_7.2
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

#install dependencies
sudo yum update -y
sudo yum install -y git perl-CPAN gcc-c++ make

#get the source code
git clone https://github.com/DOCGroup/ATCD.git
cd ATCD
WORKSPACE=`pwd`

git clone https://github.com/DOCGroup/MPC.git

#setting environment variables
export ACE_ROOT=$WORKSPACE/ACE
export DANCE_ROOT=$WORKSPACE/DAnCE
export CIAO_ROOT=$WORKSPACE/CIAO
export MPC_ROOT=$WORKSPACE/MPC
export LD_LIBRARY_PATH=$ACE_ROOT/lib

#create config.h headerfile specific to platform
touch $ACE_ROOT/ace/config.h
echo '#include "ace/config-linux.h" ' >> $ACE_ROOT/ace/config.h
touch $ACE_ROOT/include/makeinclude/platform_macros.GNU
echo 'include $(ACE_ROOT)/include/makeinclude/platform_linux.GNU' >> $ACE_ROOT/include/makeinclude/platform_macros.GNU
echo 'INSTALL_PREFIX = /usr/local' >> $ACE_ROOT/include/makeinclude/platform_macros.GNU
echo 'install_rpath=0' >> $ACE_ROOT/include/makeinclude/platform_macros.GNU

#change dir and generating make files
cd ACE && perl $ACE_ROOT/bin/mwc.pl -type gnuace ACE.mwc

#compile and install
cd $ACE_ROOT/ace && make && sudo make install

#compile and run tests
cd $ACE_ROOT/tests
perl $ACE_ROOT/bin/mwc.pl -type gnuace tests.mwc
make -j 2
perl run_test.pl

