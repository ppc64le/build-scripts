# Package : Apache Calcite
#Version : 1.19.0
#Source repo : https://github.com/apache/calcite
# Tested on : rhel_7.6
# Maintainer : lysannef@us.ibm.com
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
    VERSION="calcite-1.19.0"
fi

# Install dependencies.
yum update -y
yum install -y git wget java-11-openjdk-devel java-11-openjdk which 
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

#Install maven v3.6.2
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz 
tar xvzf apache-maven-3.6.2-bin.tar.gz
ln -s apache-maven-3.6.2 /maven
export M2_HOME=/maven
export PATH=${M2_HOME}/bin:${PATH}

#Clone and build source
git clone https://github.com/apache/calcite
cd calcite
git checkout $VERSION 
sed -i '1100s/http/https/' pom.xml 
mvn clean install -DskipTests

# Tests
mvn test
