# Package : Apache Flink
# Version : master
# Source repo : https://github.com/apache/flink
# Tested on : rhel_8.3
# Maintainer : bivasda1@in.ibm.com
#
# Disclaimer: This script has been tested in non-root (with sudo) mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Must be installed node v10.9.0
#!/bin/bash

VERSION="master"

# Install dependencies and tools.
sudo yum update -y
sudo yum install -y git wget java-1.8.0-openjdk-devel
export JAVA_HOME=export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

#Install maven v3.2.5 which is recommended by Flink 1.8.x
wget https://www-us.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz --no-check-certificate --quiet
tar xzf apache-maven-3.2.5-bin.tar.gz

export M2_HOME=`pwd`/apache-maven-3.2.5
export PATH=`pwd`/apache-maven-3.2.5/bin:${PATH}

#Clone and build source
git clone https://github.com/apache/flink.git
cd flink
git checkout $VERSION

# Updated com.google.protobuf:protoc from 3.5.1-->3.7.0
sed -i 's/3.5.1/3.7.0/g' flink-formats/flink-parquet/pom.xml

#Compile and build package using threads
mvn clean package -T 6 -DskipTests -Dfast
