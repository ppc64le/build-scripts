# ----------------------------------------------------------------------------
#
# Package	: commons-csv
# Version	: 1.5-RC1
# Source repo	: https://github.com/apache/commons-csv
# Tested on	: rhel 7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum update -y
sudo yum install -y gcc make python java-1.7.0-openjdk-devel.ppc64le \
    tar git wget

export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

wget http://archive.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz
tar -zxf apache-maven-3.3.3-bin.tar.gz
sudo mv apache-maven-3.3.3 /usr/local
rm -f apache-maven-3.3.3-bin.tar.gz
sudo ln -s /usr/local/apache-maven-3.3.3/bin/mvn /usr/bin/mvn

git clone https://github.com/apache/commons-csv
cd commons-csv
mvn dependency:list -DexcludeTransitive; mvn -DskipTests package
mvn test -fn
