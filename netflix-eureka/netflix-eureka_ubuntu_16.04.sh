# ----------------------------------------------------------------------------
#
# Package	: netflix-eureka
# Version	: 2.0.0-rc.2
# Source repo	: https://github.com/Netflix/eureka.git
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
sudo apt-get install -y git gcc ruby ant maven couchdb-bin gcc g++ make \
    openjdk-8-jre-headless openjdk-8-jdk autoconf golang-go libffi6 libffi-dev

export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-ppc64el"
export JAVA_TOOL_OPTIONS="-Dfile.encoding=en_US.UTF-8"
export PATH=$JAVA_HOME/bin:$PATH

# Install JNA libraries.
git clone https://github.com/java-native-access/jna
mkdir -p $HOME/jna/build/native-linux-ppc64le/libffi/.libs
cp /usr/lib/powerpc64le-linux-gnu/libffi.a $HOME/jna/build/native-linux-ppc64le/libffi/.libs
cd ~/jna && ant test && sudo ant install
cd

# Clone and build source code.
git clone https://github.com/Netflix/eureka.git eureka
cd ~/eureka/eureka-client
../gradlew
../gradlew assemble
