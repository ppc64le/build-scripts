# ----------------------------------------------------------------------------
#
# Package	: netflix-eureka
# Version	: 2.0.0-rc.2
# Source repo	: https://github.com/Netflix/eureka.git
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
sudo yum -y update
sudo yum install -y ant git libffi libffi-devel \
    gcc-c++ make autoconf automake libtool \
    texinfo which file libX11-devel libXt-devel \
    java-1.8.0-openjdk java-1.8.0-openjdk-devel.ppc64le java-1.8.0-openjdk-headless

# Install libffi.
cd
git clone git://github.com/atgreen/libffi.git
cd libffi && ./autogen.sh && ./configure && make

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
export PATH=$JAVA_HOME/bin:$PATH

# Install JNA libraries.
cd
git clone https://github.com/java-native-access/jna
mkdir -p $HOME/jna/build/native-linux-ppc64le/libffi/.libs
ln -s $HOME/libffi/powerpc64le-unknown-linux-gnu/.libs/libffi.a $HOME/jna/build/native-linux-ppc64le/libffi/.libs/libffi.a
cd ~/jna
git checkout 4.1.0
ant test
sudo ln -s ~/jna/build/classes/com/sun/jna/linux-ppc64le/libjnidispatch.so $JAVA_HOME/jre/lib/ppc64le/libjnidispatch.so

# Clone and build source code.
cd
git clone https://github.com/Netflix/eureka.git
cd /root/eureka/eureka-client
../gradlew build
export jarpath=`find / -name "jna*" | grep modules | grep jar | grep -v platform`
sudo cp ~/jna/dist/jna.jar $jarpath
cd ~/eureka/eureka-client
../gradlew build
../gradlew assemble
