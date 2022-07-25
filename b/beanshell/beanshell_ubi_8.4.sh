#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : BeanShell
# Version       : 2.0b6
# Source repo   : https://github.com/beanshell/beanshell
# Tested on     : UBI: 8.4
# Script License: Apache License 2.0
# Maintainer    : Sapana Khemkar <Sapana.Khemkar@ibm.com>/ Balavva Mirji <Balavva.Mirji@ibm.com>
# Language	    : Java
# Travis-Check  : True
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=beanshell
PACKAGE_URL=https://github.com/beanshell/beanshell.git
PACKAGE_VERSION=${1:-2.0b6}

# install tools and dependent packages
yum install -y git wget

# install java
yum -y install java-1.8.0-openjdk-devel

#install ant
antversion=1.10.12
wget http://archive.apache.org/dist/ant/binaries/apache-ant-${antversion}-bin.tar.gz
tar xvfvz apache-ant-${antversion}-bin.tar.gz -C /opt
ln -sfn /opt/apache-ant-${antversion} /opt/ant
sh -c 'echo ANT_HOME=/opt/ant >> /etc/environment'
ln -sfn /opt/ant/bin/ant /usr/bin/ant
ant -version

# Cloning the repository from remote to local
cd /home 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


#ant install 
ant
ant test 

exit 0
