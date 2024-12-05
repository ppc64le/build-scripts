#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : bitnami/containers/postgresql
# Version       : d5b1f7a
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

PACKAGE_VERSION=${1:-d5b1f7a}
PACKAGE_NAME=postgresql
PACKAGE_URL=https://github.com/bitnami/containers
POSTGRESQL_MAJOR=14
POSTGRESQL_MAJOR_VERSION=14.13.0

wdir=$(pwd)
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

yum install git -y 

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

# Clone the repository and build image
cd $wdir
git clone $PACKAGE_URL
cd containers
git checkout $PACKAGE_VERSION
cd bitnami/$PACKAGE_NAME/$POSTGRESQL_MAJOR/debian-12
git apply $SCRIPT_DIR/postgresql-bv_$POSTGRESQL_MAJOR_VERSION.patch
docker build -t postgresql-bv:$POSTGRESQL_MAJOR_VERSION .
