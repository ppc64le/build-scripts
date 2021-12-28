# ----------------------------------------------------------------------------
#
# Package       : foundationdb
# Version       : 7.0.0
# Source repo   : https://github.com/vikasgupta8/foundationdb
# Tested on     : rhel UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer's  : Santosh Magdum <santosh.magdum@us.ibm.com>
#                 Priya Seth <priya.seth@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

PACKAGE_NAME=foundationdb
PACKAGE_PATH=github.com/eclipse-vertx/vert.x
PACKAGE_VERSION=${1:-7.0.0}
PACKAGE_URL=https://github.com/vikasgupta8/foundationdb

BUILD_HOME=`pwd`

yum install -y wget make gcc-c++ openssl-devel tar nano

yum install -y java-1.8.0-openjdk-devel mono-devel lz4-devel

yum install -y  perl-Test-Simple perl-IPC-Cmd perl-Test-Harness perl-Math-BigInt perl-Data-Dumper
yum install -y --nobest  perl-Pod-Html

ln -s /usr/bin/python3 /usr/bin/python
python --version

# ------- Clone and build source -------
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-2.el8_5.ppc64le/


# --------- Installing cmake version 3.21.2 -----------------
echo "--------- Installing cmake version 3.21.2 -----------------"

wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz
tar -xvf cmake-3.21.2.tar.gz
cd cmake-3.21.2
./bootstrap
make
make install
cd ..

# --------- Installing ninja version v1.4.0 -----------------
echo "--------- Installing ninja version v1.4.0 -----------------"

git clone git://github.com/ninja-build/ninja.git
cd ninja
git checkout v1.4.0
./bootstrap.py
cp -r ./ninja /usr/bin/
ninja --version
cd ..

git clone --recurse https://github.com/lz4/lz4.git
cd lz4
make 
make install

git clone https://github.com/openssl/openssl.git
cd openssl
./config
make 
make install

#git clone --recurse https://github.com/vikasgupta8/foundationdb.git
git clone --recurse $PACKAGE_URL

cd $PACKAGE_NAME

#mkdir build
#cd build

#cmake -G Ninja ..

 
