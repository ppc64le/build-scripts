#!/bin/bash -e

# ----------------------------------------------------------------------------
#
# Package	      : xmlbeans
# Version	      : REL_5_0_2
# Source repo	  : https://github.com/apache/xmlbeans
# Tested on	    : ubi 8.5
# Script License: Apache License Version 2.0
# Maintainer	  : Bhagat Singh <Bhagat.singh1@ibm.com>
# Language	    : Java
# Travis-Check  : True
# Disclaimer    : This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=xmlbeans
PACKAGE_URL=https://github.com/apache/xmlbeans.git
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-REL_5_0_2}

#Dependencies
yum install -y java-11-openjdk-devel git wget unzip
cd /opt/
wget https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.12-bin.zip
unzip apache-ant-1.10.12-bin.zip
export ANT_HOME=/opt/apache-ant-1.10.12
export PATH=/opt/apache-ant-1.10.12/bin:$PATH
export ANT_OPTS=-Dfile.encoding=UTF8

# Cloning the repository from remote to local
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
ant clean
ant test -v
