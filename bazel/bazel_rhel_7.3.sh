# ----------------------------------------------------------------------------
#
# Package	: bazel
# Version	: 0.4.5
# Source repo	: https://github.com/bazelbuild/bazel.git
# Tested on	: rhel_7.3
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

# Install required dependencies.
sudo yum update -y
sudo yum install -y java-1.8.0-openjdk-devel.ppc64le

#Set Java_HOME , JRE_HOME and PATH
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH
wdir=`pwd`

# ### A. Install Protobuf for Bazel. ###
sudo yum install -y autoconf automake libtool curl make gcc-c++ unzip zip git
git clone https://github.com/ibmsoe/protobuf-1/ protobuf
        cd protobuf
        git checkout r3.0.0-ppc
        ./autogen.sh
        ./configure --prefix=/opt/DL/protobuf
        sed -i "s/^LDFLAGS = -static/LDFLAGS = -all-static/g" src/Makefile
        make
        sudo make install

export PROTOC=/opt/DL/protobuf/bin/protoc

# ### B. Build grpc-java 1.0.0 for Bazel ###

# ### I.Build protobuf 3.0.0b3 for grpc-java
cd $wdir
git clone https://github.com/google/protobuf.git protobuf3.0
        cd protobuf3.0
        git checkout v3.0.0-beta-3
        sudo git cherry-pick 1760feb621a913189b90fe8595fffb74bce84598
        ./autogen.sh
        ./configure
        make
        sudo make install

# ### II. Build grpc-java
cd $wdir
sudo yum install -y libstdc++-static.ppc64le
git clone https://github.com/grpc/grpc-java.git
        cd grpc-java
        git checkout v1.0.0
        export CXXFLAGS="-I$wdir/protobuf3.0/src" LDFLAGS="-L$wdir/protobuf3.0/src/.libs"
        sudo git cherry-pick 862157a84be602c1cabfb46958511489337bfd36
        cd compiler
        GRPC_BUILD_CMD="../gradlew java_pluginExecutable"
        eval $GRPC_BUILD_CMD
export GRPC_JAVA_PLUGIN=$wdir/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java

# ### C. Build Bazel 0.4.5 for Tensorflow ###
cd $wdir
git clone https://github.com/bazelbuild/bazel.git
        cd bazel
        git checkout 0.4.5
        ./compile.sh
        PATH=$wdir/bazel/output:$PATH
