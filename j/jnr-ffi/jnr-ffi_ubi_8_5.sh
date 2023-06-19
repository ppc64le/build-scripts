#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : jnr-ffi
# Version       : jnr-ffi-2.2.13
# Source repo   : https://github.com/jnr/jnr-ffi
# Tested on     : UBI: 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=jnr-ffi
PACKAGE_URL=https://github.com/jnr/jnr-ffi


# Default tag jnr-ffi
if [ -z "$1" ]; then
  export PACKAGE_VERSION="jnr-ffi-2.2.13"
else
  export PACKAGE_VERSION="$1"
fi

yum install -y git wget curl unzip gcc gcc-c++  make dos2unix 

#installing java-11
yum install -y java-11-openjdk-devel.ppc64le
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH



#installing maven 3.8.6
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.6-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.6-bin.tar.gz
mv /usr/local/apache-maven-3.8.6 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

# Cloning the repository 
git clone $PACKAGE_URL
cd ${PACKAGE_NAME}
git checkout $PACKAGE_VERSION

sed -i 's/if (getCPU() == CPU.X86_64) {/if (getCPU() == CPU.PPC64LE) {/g' src/main/java/jnr/ffi/Platform.java

#build and test package
if ! mvn clean install -DskipTests; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi
if ! mvn test ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi
