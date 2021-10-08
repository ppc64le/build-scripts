# ----------------------------------------------------------------------------
#
# Package       : java-statsd-client
# Version       : 3.1.0
# Source repo   : https://github.com/tim-group/java-statsd-client
# Tested on     : ubi: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Hari Pithani <Hari.Pithani@ibm.com>
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

echo "Usage: $0 [<PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is 3.1.0"

#Variables.
PACKAGE_VERSION=v3.1.0
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"
PACKAGE_NAME=java-statsd-client/
PACKAGE_URL=https://github.com/tim-group/java-statsd-client.git

# Installation of Utilities. 
yum update -y
yum install git wget java-11-openjdk-devel -y 

# ANT installation
wget https://downloads.apache.org//ant/binaries/apache-ant-1.10.11-bin.tar.gz
tar -zxvf apache-ant-1.10.11-bin.tar.gz
mv apache-ant-1.10.11 /opt/
rm -rf apache-ant-1.10.11-bin.tar.gz
export ANT_HOME=/opt/apache-ant-1.10.11
export PATH=$PATH:$ANT_HOME/bin

# Cloning the repository from remote to local. 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${PACKAGE_VERSION} found to checkout"
else
  echo  "${PACKAGE_VERSION} not found"
  exit
fi

# Build and test
ant jar
ant test


