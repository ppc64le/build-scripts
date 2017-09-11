# ----------------------------------------------------------------------------
#
# Package	: bazel
# Version	: 0.4.5
# Source repo	: https://github.com/bazelbuild/bazel/releases
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Sandip Giri <sgiri@us.ibm.com>
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
sudo apt-get install -y openjdk-8-jdk wget autoconf libtool curl make \
    unzip zip git g++

# Set up environment.
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH
wdir=`pwd`

# Clone and build source code.
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/0.4.5/bazel-0.4.5-dist.zip
unzip bazel-0.4.5-dist.zip
./compile.sh
export PATH=$PATH:$wdir/bazel/output
