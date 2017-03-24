# ----------------------------------------------------------------------------
#
# Package	: ACE
# Version	: 6.4.2
# Source repo	: https://github.com/DOCGroup/ATCD.git
# Tested on	: ubuntu_16.04
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

# Install all dependencies.
sudo apt-get update -y
sudo apt-get install -y git build-essential

# Clone ACE source.
git clone http://github.com/DOCGroup/ATCD.git
cd ATCD/ACE
export ACE_ROOT=`pwd`
git clone https://github.com/DOCGroup/MPC.git MPC
$ACE_ROOT/bin/mwc.pl -type gnuace ACE.mwc

# These changes are required to build ACE correctly.
echo "#include \"ace/config-linux.h\"" > $ACE_ROOT/ace/config.h
echo "include \$(ACE_ROOT)/include/makeinclude/platform_linux.GNU" > $ACE_ROOT/include/makeinclude/platform_macros.GNU
export LD_LIBRARY_PATH=$ACE_ROOT/lib:$LD_LIBRARY_PATH; export LD_LIBRARY_PATH

# Build and run tests.
make
perl bin/auto_run_tests.pl -a -Config FIXED_BUGS_ONLY -Config FACE_SAFETY

