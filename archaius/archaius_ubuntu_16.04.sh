# ----------------------------------------------------------------------------
#
# Package	: archaius
# Version	: 2.2.13
# Source repo	: https://github.com/Netflix/archaius.git
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

sudo apt-get update -y
sudo apt-get install -y git ant openjdk-8-jdk openjdk-8-jre libffi-dev make \
  gcc

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# To deal with build failure "java.lang.OutOfMemoryError: Permgen space"
export JAVA_OPTS=-"XX:PermSize=256m -XX:MaxPermSize=512m"
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
sudo locale-gen en_US.UTF-8

WDIR=`pwd`
# Install JNA libraries.
git clone https://github.com/java-native-access/jna
mkdir -p $HOME/jna/build/native-linux-ppc64le/libffi/.libs
cp /usr/lib/powerpc64le-linux-gnu/libffi.a $HOME/jna/build/native-linux-ppc64le/libffi/.libs
cd jna && (sudo ant test || true) && (sudo ant test-platform || true) && sudo ant dist

sudo ln -s $HOME/jna/build/classes/com/sun/jna/linux-ppc64le/libjnidispatch.so \
    /usr/lib/jvm/java-1.8.0-openjdk-ppc64el/jre/lib/ppc64le/libjnidispatch.so
export jarpath=`find / -name "jna-[1-9]*" | grep modules | grep jar`
echo $jarpath
sudo cp $HOME/jna/dist/jna.jar $jarpath

# Build archaius package.
cd $WDIR
git clone https://github.com/Netflix/archaius.git
cd archaius
sed -i "/apply plugin: 'java'/a tasks.withType(JavaCompile) { options.encoding = 'UTF-8' }" build.gradle
./gradlew clean build
