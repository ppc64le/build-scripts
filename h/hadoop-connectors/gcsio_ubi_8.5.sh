# ----------------------------------------------------------------------------
#
# Package       : gcsio
# Version       : master
# Source repo   : https://github.com/GoogleCloudDataproc/hadoop-connectors
# Tested on     : UBI: 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -e 

PACKAGE_NAME=gcsio
PACKAGE_VERSION=${1:-master}              
PACKAGE_URL=https://github.com/GoogleCloudDataproc/hadoop-connectors

# install dependencies
yum install -y git wget java-1.8.0-openjdk-devel 

# install maven
wget https://dlcdn.apache.org/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz
tar -zxvf apache-maven-3.8.4-bin.tar.gz
mv apache-maven-3.8.4 /opt/maven
export M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}

# clone package
git clone $PACKAGE_URL
cd hadoop-connectors
git checkout $PACKAGE_VERSION 

mvn -P hadoop1 clean package