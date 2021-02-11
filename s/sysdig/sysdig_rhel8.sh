
# ----------------------------------------------------------------------------
#
# Package       : sysdig
# Version       : 0.27.1
# Source repo   : https://github.com/draios/sysdig.git
# Tested on     : RHEL 8.2 
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Shirodkar <amit.shirodkar@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode using sudo on the platform
# ==========  as specified, and the version of the package as indicated.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such casea, please
#             contact the "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


sudo yum install git kernel-headers kernel-devel gcc libgcc gcc-c++ cmake make wget patch python36 c-ares c-ares-devel -y 
git clone https://github.com/draios/sysdig.git
cd sysdig
git apply ../sysdig_dynamic_stdlib.patch

mkdir build
cd build 
cmake ..
make 
make package 
make run-unit-tests
