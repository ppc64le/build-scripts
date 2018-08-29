# ----------------------------------------------------------------------------
#
# Package       : checker-compat-qual 
# Version       : 2.5.4
# Source repo   : https://github.com/typetools/checker-framework.git 
# Tested on     : ubuntu_18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Sandip Giri <sgiri@us.ibm.com>
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
sudo apt-get install -y ant dia git hevea junit4 librsvg2-bin unzip \
    libcurl3-gnutls make maven mercurial openjdk-8-jdk texlive-latex-base \
    texlive-latex-recommended texlive-latex-extra texlive-fonts-recommended wget

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el

# Clone and build source.
WDIR=`pwd`
export JSR308=$WDIR/jsr308
mkdir -p $JSR308
cd $JSR308
git clone https://github.com/typetools/checker-framework.git checker-framework
cd $JSR308/checker-framework
./gradlew cloneAndBuildDependencies

cd $JSR308/checker-framework
./gradlew assemble

export PATH=$JSR308/checker-framework/checker/bin:$JSR308/jsr308-langtools/dist/bin:${PATH}
./gradlew allTests
# (one test case is failing on both the platform, x86 and ppc64le)
