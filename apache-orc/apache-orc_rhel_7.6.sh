# ----------------------------------------------------------------------------
#
# Package	: Apache ORC
# Version	: 1.5.1
# Source repo	: https://github.com/apache/orc.git
# Tested on	: rhel_7.6
# Script License: Apache License, Version 2 or later
# Maintainer	: lysannef@us.ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

if [ "$#" -gt 0 ]
then
    VERSION=$1
else
    VERSION="1.5.1"
fi

# Install dependencies.
yum update -y
yum install autoconf automake gcc gcc-c++ glibc-devel libtool\
	 cmake3 make pkgconf–pkg-config git wget cyrus-sasl-devel\
	 ncurses-devel ncurses cyrus-sasl openssl-devel openssl\
	 doxygen libgsasl libgsasl-devel valgrind dotconf\
	 java-1.8.0-openjdk-devel protobuf-compiler -y

# Install java dependencies.
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz -P /tmp
tar -xf /tmp/apache-maven-3.6.2-bin.tar.gz -C /usr/local
ln -s /usr/local/apache-maven-3.6.2/bin/mvn /usr/bin/mvn
mvn install:install-file -DgroupId=com.google.protobuf -DartifactId=protoc -Dversion=2.5.0 -Dclassifier=linux-ppcle_64 -Dpackaging=exe -Dfile=/usr/bin/protoc

# Build curl with openssl.
wget https://curl.haxx.se/download/curl-7.67.0.tar.gz -P /tmp
tar -xf /tmp/curl-7.67.0.tar.gz -C /usr/local/src/
cd /usr/local/src/curl-7.67.0
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig
./buildconf
./configure --with-ssl
make install

# Clone source code from github.
cd /
wget https://github.com/apache/orc/archive/rel/release-$VERSION.tar.gz
tar -xvzf release-$VERSION.tar.gz
cd orc-rel-release-$VERSION

# Required changes.
# -fsigned-char flag is required because default behaviour of char type on x86 is signed-char and on power it is unsigned-char.
sed -i '68s/-O0 -g/-O0 -g -fsigned-char/' CMakeLists.txt 
sed -i '69s/-O3 -g -DNDEBUG/-O3 -g -DNDEBUG -fsigned-char/' CMakeLists.txt
sed -i '70s/-O3 -DNDEBUG/-O3 -DNDEBUG -fsigned-char/' CMakeLists.txt
# Cmake installs thirdparty-tools in lib64 folder and while testing looks for them in lib folder which throws an error.
sed -i '62s/)/ -DCMAKE_INSTALL_LIBDIR=lib)/' cmake_modules/ThirdpartyToolchain.cmake
sed -i '138s/)/ -DCMAKE_INSTALL_LIBDIR=lib)/' cmake_modules/ThirdpartyToolchain.cmake
sed -i '227s/)/ -DCMAKE_INSTALL_LIBDIR=lib)/' cmake_modules/ThirdpartyToolchain.cmake

# Build and test.
mkdir build
cd build
cmake3 -DCMAKE_BUILD_TYPE=RELEASE ..
make package 
make test-out

