# ----------------------------------------------------------------------------
#
# Package       : java-statsd-client
# Version       : v3.1.0
# Source repo   : https://github.com/tim-group/java-statsd-client
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Jotirling Swami <Jotirling.Swami1@ibm.com>
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

# Variables
REPO=https://github.com/tim-group/java-statsd-client.git
VERSION=v3.1.0
DIR=java-statsd-client

# install tools and dependent packages
yum update -y
yum install -y git wget


# install java
yum install -y java-11-openjdk-devel

#install Ant
antversion=1.10.3
wget http://archive.apache.org/dist/ant/binaries/apache-ant-${antversion}-bin.tar.gz
tar xvfvz apache-ant-${antversion}-bin.tar.gz -C /opt
ln -sfn /opt/apache-ant-${antversion} /opt/ant
sh -c 'echo ANT_HOME=/opt/ant >> /etc/environment'
ln -sfn /opt/ant/bin/ant /usr/bin/ant
ant -version

# Cloning the repository from remote to local
cd /home
git clone $REPO
cd $DIR
git checkout $VERSION

# Build and test package
ant