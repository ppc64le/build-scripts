# ----------------------------------------------------------------------------
#
# Package	: netflix_governator
# Version	: 1.16.0
# Source repo	: https://github.com/Netflix/governator.git
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

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y wget git zip libjna-java openjdk-8-jdk openjdk-8-jre openjdk-8-jdk-headless
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin
sudo cp /usr/share/java/jna.jar $JAVA_HOME/jre/lib/ext/

# Clone and build governator.
git clone https://github.com/Netflix/governator.git
cd governator
./gradlew
