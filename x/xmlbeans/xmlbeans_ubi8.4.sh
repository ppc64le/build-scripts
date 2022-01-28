# ----------------------------------------------------------------------------
#
# Package	: xmlbeans
# Version	: REL_5_0_2
# Source repo	: https://github.com/apache/xmlbeans
# Tested on	: ubi 8.4
# Script License: Apache License Version 2.0
# Maintainer	: Sapana Khemkar <sapana.khemkar@ibm.com>
# Languge	: Java
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

# Variables
PACKAGE_NAME=xmlbeans
PACKAGE_URL=https://github.com/apache/xmlbeans.git
PACKAGE_VERSION=REL_5_0_2


# install tools and dependent packages
yum install -y git wget  unzip

# install java
yum -y install java-1.8.0-openjdk-devel

#install ant
wget https://archive.apache.org/dist/ant/binaries/apache-ant-1.10.9-bin.zip
unzip apache-ant-1.10.9-bin.zip
mv apache-ant-1.10.9/ /opt/ant
ln -s /opt/ant/bin/ant /usr/bin/ant

# Cloning the repository from remote to local
cd /home
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
ant clean
ant test -v

exit 0
