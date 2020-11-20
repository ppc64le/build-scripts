# ----------------------------------------------------------------------------
#
# Package	: netflix-feign
# Version	: 8.18.0
# Source repo	: https://github.com/Netflix/feign.git
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
    texinfo which file libX11-devel libXt-devel subversion maven \
    java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless

# Set up locale and install JNA.
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
git clone https://github.com/java-native-access/jna
cd jna
ant
ant test
sudo ant install
cd

export LANG=en_US.UTF-8
export LANGUAGE=en_US:en

# Clone and build the source code.
git clone https://github.com/Netflix/feign.git
cd feign
mv ribbon/src/test/java/feign/ribbon/RibbonClientTest.java ribbon/src/test/java/feign/ribbon/RibbonClientTest.java-ORG
./mvnw install -DskipTests=true
./mvnw test
