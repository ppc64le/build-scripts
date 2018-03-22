# ----------------------------------------------------------------------------
#
# Package       : Reactivex rxNetty
# Version       : 0.5.2
# Source repo   : https://github.com/ReactiveX/RxNetty
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install Dependencies
sudo apt-get update
sudo apt-get install -y build-essential g++ ant wget git \
    software-properties-common openjdk-8-jdk openjdk-8-jre libffi-dev

# Set Environment
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$JAVA_HOME/bin:$PATH

# Need to build JNA from source for missing library errors (libjnidispatch.so)
cd /tmp && git clone https://github.com/java-native-access/jna
mkdir -p /tmp/jna/build/native-linux-ppc64le/libffi/.libs
cd jna && git checkout 4.1.0
sudo ln -s /usr/lib/powerpc64le-linux-gnu/libffi.a /tmp/jna/build/native-linux-ppc64le/libffi/.libs/libffi.a && \
    (sudo ant test || true) && (sudo ant test-platform || true) && (sudo ant dist || true)
sudo ln -s /tmp/jna/build/classes/com/sun/jna/linux-ppc64le/libjnidispatch.so /usr/lib/jvm/java-1.8.0-openjdk-ppc64el/jre/lib/ppc64le/libjnidispatch.so

# Download source and build
cd $HOME
git clone https://github.com/ReactiveX/RxNetty
cd RxNetty
./gradlew assemble
