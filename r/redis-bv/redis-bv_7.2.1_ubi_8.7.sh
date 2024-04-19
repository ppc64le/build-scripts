#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : bitnami/containers/redis
# Version       : c277016
# Source repo   : https://github.com/bitnami/containers
# Tested on     : Red Hat Enterprise Linux 8.5 (Ootpa)
# Language      : C
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_VERSION=${1:-c277016}
PACKAGE_NAME=redis
PACKAGE_URL=https://github.com/bitnami/containers

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

yum install git wget -y 

# Install docker if not found
if ! [ $(command -v docker) ]; then
        sudo yum install -y docker
fi

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd containers
git checkout $PACKAGE_VERSION
cd bitnami/$PACKAGE_NAME/7.2/debian-11

wget https://downloads.bitnami.com/files/stacksmith/redis-7.2.1-0-linux-amd64-debian-11.tar.gz
tar -xvf redis-7.2.1-0-linux-amd64-debian-11.tar.gz

cd prebuildfs/opt/bitnami && mkdir -p redis/etc && cd redis/etc
cp $CURRENT_DIR/containers/bitnami/redis/7.2/debian-11/redis-7.2.1-linux-amd64-debian-11/files/redis/etc/redis-default.conf .

cd $CURRENT_DIR/containers/bitnami/redis/7.2/debian-11
git apply $SCRIPT_DIR/redis-bv_7.2.1.patch
docker build -t redis-bv:7.2.1 .
