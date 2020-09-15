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
sudo apt-get install -y git gradle libjna-java openjdk-8-jdk openjdk-8-jre \
    gcc g++ make automake libffi-dev build-essential
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin
cp /usr/share/java/jna.jar /usr/lib/jvm/java-8-openjdk-ppc64el/jre/lib/ext/

# Need to build Jna locally as one of the dependency 
cd /tmp && git clone https://github.com/java-native-access/jna
mkdir -p /tmp/jna/build/native-linux-ppc64le/libffi/.libs
cd jna && git checkout 4.1.0
sudo ln -s /usr/lib/powerpc64le-linux-gnu/libffi.a /tmp/jna/build/native-linux-ppc64le/libffi/.libs/libffi.a && \
    (sudo ant test || true) && (sudo ant test-platform || true) && (sudo ant dist || true)
sudo ln -s /tmp/jna/build/classes/com/sun/jna/linux-ppc64le/libjnidispatch.so /usr/lib/jvm/java-1.8.0-openjdk-ppc64el/jre/lib/ppc64le/libjnidispatch.so

# Clone and build source code.
git clone https://github.com/Netflix/pytheas
cd pytheas
./gradlew
./gradlew test
