#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : ACE_TAO
# Version               : ACE+TAO-8_0_1
# Source repo           : https://github.com/DOCGroup/ACE_TAO
# Tested on             : UBI:9.3
# Language              : C++,Perl
# Travis-Check          : True
# Script License        : Apache License 2.0 or later
# Maintainer            : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-ACE+TAO-8_0_1}
PACKAGE_NAME=ACE_TAO
PACKAGE_URL=https://github.com/DOCGroup/ACE_TAO.git

yum install -y git perl-CPAN gcc-c++ make

# Clone git repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

# Clone the MPC repository
git clone https://github.com/DOCGroup/MPC.git

# Set environment variables for ACE, TAO, and MPC
export ACE_ROOT=$(pwd)/ACE
export TAO_ROOT=$(pwd)/TAO
export MPC_ROOT=$(pwd)/MPC

# Setup ACE configuration
touch $ACE_ROOT/ace/config.h
echo '#include "ace/config-linux.h"' > $ACE_ROOT/ace/config.h

touch $ACE_ROOT/include/makeinclude/platform_macros.GNU
echo 'include $(ACE_ROOT)/include/makeinclude/platform_linux.GNU' > $ACE_ROOT/include/makeinclude/platform_macros.GNU
echo 'INSTALL_PREFIX = /usr/local' >> $ACE_ROOT/include/makeinclude/platform_macros.GNU
echo 'install_rpath=0' >> $ACE_ROOT/include/makeinclude/platform_macros.GNU

#change dir and generating make files
perl $ACE_ROOT/bin/mwc.pl -type gnuace $TAO_ROOT/TAO_ACE.mwc -workers 4
perl $ACE_ROOT/bin/mwc.pl -type gnuace $ACE_ROOT/tests/tests.mwc -workers 4
perl $ACE_ROOT/bin/mwc.pl -type gnuace $TAO_ROOT/tests/IDL_Test -workers 4
perl $ACE_ROOT/bin/mwc.pl -type gnuace $TAO_ROOT/tests/IDLv4 -workers 4

cd $ACE_ROOT

#Compile and install ACE
if ! make && make install ; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails_"
        exit 1
fi

#Build TAO_ACE (Core libraries)
if ! make -j 6 -C $TAO_ROOT ; then
       echo "------------------$PACKAGE_NAME::TAO_ACE_Build_fails-------------------------"
       echo "$PACKAGE_URL $PACKAGE_NAME"
       echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  TAO_ACE_Build_fails"
       exit 2
fi

#compile and run tests
cd $ACE_ROOT/tests
perl $ACE_ROOT/bin/mwc.pl -type gnuace tests.mwc

if ! make -j 2 ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

export LD_LIBRARY_PATH=$ACE_ROOT/lib:$LD_LIBRARY_PATH

if ! perl run_test.pl ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi
