# ----------------------------------------------------------------------------
#
# Package       : filebeat
# Version       : 6.8.10
# Source repo   : https://github.com/elastic/beats.git
# Tested on     : UBI 8.2
# Script License: Apache License Version 2.0
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export BEATS_VERSION=v6.8.10

if [ $# -ne 1 ]; then
    echo "missing argument: BEATS_VERSION to build, using default version ${BEATS_VERSION}"
else
   export BEATS_VERSION=$1
fi

export WORKDIR=`pwd`

#Install the required dependencies
yum update -y
yum install -y wget git make gcc-c++ python3-virtualenv

cd $WORKDIR
wget https://golang.org/dl/go1.10.2.linux-ppc64le.tar.gz
tar -zxvf go1.10.2.linux-ppc64le.tar.gz

export GOPATH=$WORKDIR/go
export PATH=$PATH:$GOPATH/bin

#Clone and build the source
mkdir -p ${GOPATH}/src/github.com/elastic
cd ${GOPATH}/src/github.com/elastic
git clone https://github.com/elastic/beats.git
cd beats
git checkout $BEATS_VERSION
cd filebeat
make
make unit

./filebeat version

