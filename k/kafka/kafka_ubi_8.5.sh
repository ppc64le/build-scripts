# ----------------------------------------------------------------------------
# Package       : kafka
# Version       : 2.8.0
# Source repo   : https://github.com/apache/kafka
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Kandarpa Malipeddi <kandarpa.malipeddi@ibm.com>, Amol Patil <amol.patil2@ibm.com>, Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash =e

PACKAGE_VERSION=${1:-'2.8.0'}

#Install dependencies
sudo yum install -y java-1.8.0-openjdk-devel git

export JAVA_HOME=/usr/lib/jvm/java-1.8.0
export PATH=$JAVA_HOME/bin:$PATH

#Build and run unit tests
cd $HOME
git clone https://github.com/apache/kafka
cd kafka
git checkout $PACKAGE_VERSION

./gradlew jar

./gradlew unitTest integrationTest --continue -PtestLoggingEvents=started,passed,skipped,failed -PignoreFailures=true -PmaxParallelForks=2

# Unit test will take more than 2 hrs, hence Travis-check disabled.
# There are known failures, hence -PigonreFailures=true been provided.

