# ----------------------------------------------------------------------------
#
# Package       : Apache Hive
# Version       : 3.1.2
# Source repo   : https://github.com/apache/hive.git
# Tested on     : rhel 7.6
# Script License: Apache License Version 2.0
# Maintainer    : Lysanne Fernandes <lysannef@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

VERSION=3.1.2

yum update -y 
yum install -y git wget java-1.8.0-openjdk java-1.8.0-openjdk-devel protobuf-compiler patch
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk 

#maven installation
wget https://archive.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz

tar xvzf apache-maven-3.6.2-bin.tar.gz
ln -s apache-maven-3.6.2 /maven
export M2_HOME=/maven
export PATH=${M2_HOME}/bin:${PATH}

wget https://github.com/apache/hive/archive/rel/release-$VERSION.tar.gz
tar -xvzf release-$VERSION.tar.gz
cd  hive-rel-release-$VERSION

mvn install:install-file -DgroupId=com.google.protobuf -DartifactId=protoc -Dversion=2.5.0 -Dclassifier=linux-ppcle_64 -Dpackaging=exe -Dfile=/usr/bin/protoc

sed -i '137s/try/if(wrapper != null) { try/'  llap-tez/src/test/org/apache/hadoop/hive/llap/tezplugins/TestLlapTaskCommunicator.java
sed -i '191s/}/}}/'  llap-tez/src/test/org/apache/hadoop/hive/llap/tezplugins/TestLlapTaskCommunicator.java

mvn clean install

#Run tests
#mvn test

