#----------------------------------------------------------------------------
#
# Package       : ejml
# Version       : 0.33
# Source repo   : https://github.com/lessthanoptimal/ejml
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum update -y
sudo yum install -y java-1.8.0-openjdk-devel git

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

git clone https://github.com/lessthanoptimal/ejml
cd ejml
./gradlew autogenerate
./gradlew install
./gradlew test
