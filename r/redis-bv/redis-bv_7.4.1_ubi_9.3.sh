#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : bitnami/containers/redis
# Version       : 8a26020
# Source repo   : https://github.com/bitnami/containers
# Tested on     : UBI 9.3
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

PACKAGE_VERSION=${1:-8a26020}
PACKAGE_NAME=redis
PACKAGE_URL=https://github.com/bitnami/containers
REDIS_MAJOR=7.4
REDIS_MAJOR_VERSION=7.4.1

wdir=$(pwd)
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

yum install git wget -y 

# Install docker if not found
if ! [ $(command -v docker) ]; then
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
mkdir -p /etc/docker
touch /etc/docker/daemon.json
cat <<EOT > /etc/docker/daemon.json
{
"ipv6": true,
"fixed-cidr-v6": "2001:db8:1::/64",
"mtu": 1450
}
EOT
dockerd > /dev/null 2>&1 &
sleep 5
fi

#clone and build image
cd $wdir
git clone $PACKAGE_URL
cd containers
git checkout $PACKAGE_VERSION
cd bitnami/$PACKAGE_NAME/$REDIS_MAJOR/debian-12

wget https://downloads.bitnami.com/files/stacksmith/redis-$REDIS_MAJOR_VERSION-1-linux-amd64-debian-12.tar.gz
tar -xvf redis-$REDIS_MAJOR_VERSION-1-linux-amd64-debian-12.tar.gz

cd prebuildfs/opt/bitnami && mkdir -p redis/etc && cd redis/etc
cp $wdir/containers/bitnami/redis/$REDIS_MAJOR/debian-12/redis-$REDIS_MAJOR_VERSION-linux-amd64-debian-12/files/redis/etc/redis-default.conf .

cd $wdir/containers/bitnami/redis/$REDIS_MAJOR/debian-12
git apply $SCRIPT_DIR/redis-bv_$REDIS_MAJOR_VERSION.patch
docker build -t redis-bv:$REDIS_MAJOR_VERSION .
