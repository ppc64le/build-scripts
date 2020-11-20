# ----------------------------------------------------------------------------
#
# Package	: netflix-pytheas
# Version	: 1.29.1
# Source repo	: https://github.com/Netflix/pytheas
# Tested on	: rhel_7.3
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
sudo yum update -y
sudo yum install -y java-1.7.0-openjdk java-1.7.0-openjdk-devel jna git gradle
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin
cp /usr/share/java/jna.jar /usr/lib/jvm/jre/lib/ext/

# Clone and build source code.
git clone https://github.com/Netflix/pytheas
cd pytheas
./gradlew
./gradlew test
