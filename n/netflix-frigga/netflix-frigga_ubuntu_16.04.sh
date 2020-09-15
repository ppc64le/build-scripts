# ----------------------------------------------------------------------------
#
# Package	: netflix-frigga
# Version	: 0.18.0
# Source repo	: https://github.com/Netflix/frigga.git
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
sudo apt-get install -y ant maven git libffi-dev build-essential \
     openjdk-8-jdk openjdk-8-jre openjdk-8-jre-headless

# Configure environment.
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

# Install JNA.
cd
git clone https://github.com/java-native-access/jna
mkdir -p $HOME/jna/build/native-linux-ppc64le/libffi/.libs
git checkout 4.1.0
ln -s /usr/lib/powerpc64le-linux-gnu/libffi.a \
    $HOME/jna/build/native-linux-ppc64le/libffi/.libs/libffi.a
cd jna && (ant test || true) && (ant test-platform || true) && ant dist

sudo ln -s $HOME/jna/build/classes/com/sun/jna/linux-ppc64le/libjnidispatch.so \
    /usr/lib/jvm/java-1.8.0-openjdk-ppc64el/jre/lib/ppc64le/libjnidispatch.so
export jarpath=`find / -name "jna-[1-9]*" | grep modules | grep jar`
sudo cp /root/jna/dist/jna.jar $jarpath
cd

# Clone and build source code.
git clone https://github.com/Netflix/frigga.git
cd frigga && ./gradlew
