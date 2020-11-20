# ----------------------------------------------------------------------------
#
# Package	: netflix_governator
# Version	: 1.16.0
# Source repo	: https://github.com/Netflix/governator.git
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
yum install -y wget java-1.7.0-openjdk java-1.7.0-openjdk-devel git zip jna
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin
cp /usr/share/java/jna.jar /usr/lib/jvm/jre/lib/ext/

# Clone and build governator.
git clone https://github.com/Netflix/governator.git

# nebula.netflixoss plugin has moved on to v3.6.0 and v3.5.2 is not
# availble. Update the version else the build will fail otherwise.
sed -i -e "s/'nebula.netflixoss' version '3.5.2'/'nebula.netflixoss' version '3.6.0'/" governator/build.gradle
cd governator
./gradlew
