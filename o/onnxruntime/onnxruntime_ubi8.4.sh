# -----------------------------------------------------------------------------
#
# Package       : onnxruntime
# Version       : 1.10.0
# Source repo   : https://github.com/microsoft/onnxruntime.git
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Sapana Khemkar {Sapana.Khemkar@ibm.com}
# Languge	: C++ 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=onnxruntime
PACKAGE_VERSION=1.10.0
PACKAGE_URL=https://github.com/microsoft/onnxruntime.git

set -e
yum install -y python3 git cmake gcc-c++ java-1.8.0-openjdk-devel
cd /home

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout v$PACKAGE_VERSION
./build.sh

exit 0

