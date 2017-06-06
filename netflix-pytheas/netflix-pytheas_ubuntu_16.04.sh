# ----------------------------------------------------------------------------
#
# Package	: netflix-pytheas
# Version	: 1.29.1
# Source repo	: https://github.com/Netflix/pytheas
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
sudo apt-get install -y git gradle libjna-java openjdk-8-jdk openjdk-8-jre
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin
cp /usr/share/java/jna.jar /usr/lib/jvm/java-8-openjdk-ppc64el/jre/lib/ext/

# Clone and build source code.
git clone https://github.com/Netflix/pytheas
cd pytheas
./gradlew
./gradlew test
