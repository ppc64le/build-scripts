# ----------------------------------------------------------------------------
#
# Package       : spring-boot
# Version       : 2.2.0.BUILD-SNAPSHOT
# Source repo   : https://github.com/google/conscrypt
# Tested on     : rhel_7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Shirodkar <amit.shirodkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

yum update -y
yum install git -y
yum install java-1.8.0-openjdk-devel.ppc64le -y
yum install wget -y
yum install gcc-c++ -y
yum install -y net-snmp-libs.ppc64le net-snmp-agent-libs.ppc64le make

export CWD=`pwd`
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# get boringssl 
git clone https://github.com/google/boringssl.git 
cd boringssl 
git checkout -b 9c49713ba8280deb1a1fcd7d018045ce0850115f
export BORINGSSL_HOME=`pwd`
cd $CWD

# get conscrypt 
git clone https://github.com/google/conscrypt.git
cd conscrypt
export CONSCRYPT_HOME=`pwd`
git checkout 3c5329905dc697a3e27a177615cc2686fab7723d && git apply ../conscrypt.patch
cd $CWD

# download cmake
wget https://github.com/Kitware/CMake/releases/download/v3.15.4/cmake-3.15.4.tar.gz
tar -xvzf cmake-3.15.4.tar.gz -C /opt/
cd /opt/cmake-3.15.4
./bootstrap && make
cd bin
export PATH=`pwd`:$PATH

#download ninja
cd /opt/
git clone https://github.com/ninja-build/ninja.git
cd ninja 
./bootstrap.py
export PATH=`pwd`:$PATH
cd $CWD

#download go
wget https://dl.google.com/go/go1.13.1.linux-ppc64le.tar.gz
tar -xvzf go1.13.1.linux-ppc64le.tar.gz -C /opt
export PATH=/opt/go/bin:$PATH

#now build boringssl 
cd $BORINGSSL_HOME
mkdir buildppc64le
cd buildppc64le
cmake -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_ASM_FLAGS=-Wa,--noexecstack \
      -GNinja ..
ninja

# build conscrypt
cd $CONSCRYPT_HOME
./gradlew build -x conscrypt-openjdk:linux_ppc64leTest -x conscrypt-openjdk-integ-tests:testEngineSocket -x conscrypt-openjdk-integ-tests:testEngineSocket -x conscrypt-openjdk-integ-tests:test
./gradlew install 
# copy .so
cp openjdk/build/libs/conscrypt_openjdk_jni/shared/libconscrypt_openjdk_jni.so $JAVA_HOME/jre/lib/ppc64le/


cd /opt/
wget https://archive.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz
tar -xvzf apache-maven-3.6.2-bin.tar.gz
export PATH=/opt/apache-maven-3.6.2/bin/:$PATH

cd $CWD
git clone https://github.com/flapdoodle-oss/de.flapdoodle.embed.process.git
cd de.flapdoodle.embed.process
git checkout de.flapdoodle.embed.process-2.1.2 && git apply ../de.flapdoodle.embed.process.patch
mvn clean install -DskipTests

#Download enterprise edition mongodb in /opt/
#create symbolic links

cd $CWD
git clone https://github.com/flapdoodle-oss/de.flapdoodle.embed.mongo.git
cd de.flapdoodle.embed.mongo
git checkout 4e9ffbe26f02d0560d8d9e4ab73f3aca0f399681 && git apply ../de.flapdoodle.embed.mongo.patch
mvn clean install -DskipTests

#build spring-boot

cd $CWD
git clone https://github.com/spring-projects/spring-boot
cd spring-boot
git checkout b9bb84236b39d25957694ecbed44116e9878bf39 && git apply ../spring-boot-conscrypt.patch
# install conscrypt jars
./mvnw install:install-file -Dfile=$CONSCRYPT_HOME/openjdk/build/libs/conscrypt-openjdk-2.3.0-SNAPSHOT.jar -DgroupId=org.conscrypt -DartifactId=conscrypt-openjdk-uber -Dversion=2.3.0-SNAPSHOT -Dpackaging=jar -DgeneratePom=true
./mvnw clean install

