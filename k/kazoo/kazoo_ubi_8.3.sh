# ----------------------------------------------------------------------------
#
# Package       : kazoo
# Version       : 2.8.0
# Source repo   : https://github.com/python-zk/kazoo.git
# Tested on     : UBI: 8.3
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

# Default tag for kazoo
if [ -z "$1" ]; then
  export VERSION="2.8.0"
else
  export VERSION="$1"
fi#

# Variables
REPO=https://github.com/python-zk/kazoo.git

# install tools and dependent packages
yum update -y
yum install -y git wget python3 python38 python38-pip python38-devel python3-devel make gcc gcc-c++ maven libevent-devel.ppc64le krb5-devel.ppc64le  krb5-libs.ppc64le
ln -s /usr/bin/python3.8 /usr/bin/python

# install ant
wget https://downloads.apache.org//ant/binaries/apache-ant-1.10.11-bin.tar.gz
tar -zxvf apache-ant-1.10.11-bin.tar.gz
mv apache-ant-1.10.11 /opt/
sed -i "$ a export ANT_HOME=/opt/apache-ant-1.10.11" /etc/profile
sed -i "$ a export PATH=\${PATH}:\${ANT_HOME}/bin" /etc/profile
source /etc/profile

# cloning Repo
git clone $REPO
cd kazoo
git checkout ${VERSION}

# build and test the package
pip3 install tox
export ZOOKEEPER_VERSION=3.5.8 ZOOKEEPER_PREFIX="apache-" ZOOKEEPER_SUFFIX="-bin" ZOOKEEPER_LIB="lib" TOX_VENV=py38-gevent-eventlet-sasl,codecov DEPLOY=true
sh ensure-zookeeper-env.sh
tox -e ${TOX_VENV}