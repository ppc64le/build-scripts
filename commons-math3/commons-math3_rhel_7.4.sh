# ----------------------------------------------------------------------------
#
# Package       : Apache Commons Math3
# Version       : MATH_3_6_1
# Source repo   : https://github.com/apache/commons-math.git
# Tested on     : rhel_7.4
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

sudo yum -y update
sudo yum -y install git java-1.8.0-openjdk-devel wget
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

wget http://www-eu.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz
tar xzvf apache-maven-3.5.2-bin.tar.gz
export PATH=$PATH:`pwd`/apache-maven-3.5.2/bin
rm -rf apache-maven-3.5.2-bin.tar.gz

git clone https://github.com/apache/commons-math.git
cd commons-math
mvn clean test
