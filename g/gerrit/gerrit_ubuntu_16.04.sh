# ----------------------------------------------------------------------------
#
# Package       : Gerrit
# Version       : 2.13.10
# Source repo   : https://gerrit.googlesource.com/gerrit
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update
sudo apt-get install openjdk-8-jdk gcc wget git autoconf libtool curl make zip unzip -y
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el

#Download and install Bazel
mkdir bazel && cd bazel && \
wget https://github.com/bazelbuild/bazel/releases/download/0.10.0/bazel-0.10.0-dist.zip && \
unzip bazel-0.10.0-dist.zip && \
chmod -R +w . && \
./compile.sh && \
export PATH=$PATH:`pwd`/output
rm -rf bazel-0.10.0-dist.zip
cd ..

#Install Node
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source $HOME/.nvm/nvm.sh
nvm install stable
nvm use stable

#Install Maven
wget http://www-eu.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
tar xzvf apache-maven-3.5.2-bin.tar.gz
export PATH=$PATH:`pwd`/apache-maven-3.5.2/bin
rm -rf apache-maven-3.5.2-bin.tar.gz

#Clone and Build Gerrit
git clone --recursive https://gerrit.googlesource.com/gerrit
cd gerrit && bazel build release
