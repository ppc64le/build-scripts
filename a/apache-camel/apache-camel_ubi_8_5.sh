#!/bin/bash -e

# ----------------------------------------------------------------------------
#
# Package	: camel
# Version	: camel-3.20.1
# Source repo	: https://github.com/apache/camel
# Tested on	: UBI 8.5
# Language      : java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Shantanu Kadam <Shantanu.Kadam@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


# Install dependencies
yum -y update && yum install -y git wget java-11-openjdk-devel
JDK_PATHS=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JAVA_HOME=${JDK_PATHS%$'\n'*}
export PATH=$JAVA_HOME/bin:$PATH

# Install maven
wget http://archive.apache.org/dist/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz
tar -zxf apache-maven-3.8.4-bin.tar.gz
cp -R apache-maven-3.8.4 /usr/local
ln -s /usr/local/apache-maven-3.8.4/bin/mvn /usr/bin/mvn

echo "`date +'%d-%m-%Y %T'` - Installed Build Dependencies -----------------------------------"
echo "- --------------------------------------------------------------------------------------"

# Clone git repository
git clone https://github.com/apache/camel.git
cd camel/

#patch
sed -i "50 a \\\t<profile> \
        \n\t    <!-- kudu-binary is not available for power. It is needed for tests, so skip that --> \
        \n\t    <id>Power-Kudu-SkipTests</id> \
        \n\t    <activation> \
        \n\t        <os>  \
        \n\t            <family>linux</family> \
        \n\t        </os>  \
        \n\t    </activation> \
        \n\t    <properties>  \
        \n\t        <maven.test.skip>true</maven.test.skip>  \
        \n\t        <os.detected.classifier>linux-x86_64</os.detected.classifier> <!-- Fake classifier to allow dependency resolution. kudu-binary will not be executed anyway on Power -->  \
        \n\t    </properties>  \
        \n\t</profile>" components/camel-kudu/pom.xml


# Build
mvn clean install -DskipTests

# Test
mvn test -e -fae -Dnoassembly -Dmaven.test.failure.ignore=true -Dsurefire.rerunFailingTestsCount=2 

echo "`date +'%d-%m-%Y %T'` - Build and Test Completed ---------------------------------------"
echo "- --------------------------------------------------------------------------------------"

