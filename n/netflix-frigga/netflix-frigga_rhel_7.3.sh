# ----------------------------------------------------------------------------
#
# Package	: netflix-frigga
# Version	: 0.18.0
# Source repo	: https://github.com/Netflix/frigga.git
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
sudo yum install -y ant maven git libffi libffi-devel \
    gcc-c++ make autoconf automake libtool \
    openjdk-8-jdk openjdk-8-jre openjdk-8-jre-headless \
    texinfo which file libX11-devel libXt-devel

# Install libffi.
git clone git://github.com/atgreen/libffi.git
cd libffi && ./autogen.sh && ./configure && make

export JAVA_HOME="/usr/lib/jvm/java-1.8.0"
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

# Install JNA.
cd
git clone https://github.com/java-native-access/jna
mkdir -p $HOME/jna/build/native-linux-ppc64le/libffi/.libs
sudo ln -s $HOME/libffi/powerpc64le-unknown-linux-gnu/.libs/libffi.a \
    $HOME/jna/build/native-linux-ppc64le/libffi/.libs/libffi.a
cd $HOME/jna
git checkout 4.1.0
ant test
ant dist

sudo ln -s $HOME/jna/build/classes/com/sun/jna/linux-ppc64le/libjnidispatch.so \
    /usr/lib/jvm/java-1.7.0/jre/lib/ppc64le/libjnidispatch.so
cd

# Clone and build source code.
git clone https://github.com/Netflix/frigga.git
cd frigga && ./gradlew build && ./gradlew test
