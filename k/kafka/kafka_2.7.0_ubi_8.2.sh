# ----------------------------------------------------------------------------
#
# Package       : kafka
# Version       : 2.7.0
# Source repo   : https://github.com/apache/kafka
# Tested on     : UBI 8.2
# Script License: Apache License, Version 2 or later
# Maintainer    : Amol Patil <amol.patil2@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

VERSION=2.7.0

#Install dependencies
sudo yum update -y
sudo yum install -y git wget unzip java-1.8.0-openjdk java-1.8.0-openjdk-devel

#Build and run unit tests
cd $HOME
git clone https://github.com/apache/kafka
cd kafka
git checkout $VERSION

./gradlew jar
./gradlew releaseTarGz -x signArchives


# Execute unit tests
# Results are "6104 tests completed, 6 failed, 63 skipped"
# There are 6 test failures in SslTransportLayerTest test suite, parity with intel 
./gradlew unitTest

