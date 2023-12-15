#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : bitnami/containers/postgresql
# Version       : 5b5ff16
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
PACKAGE_VERSION=${1:-5b5ff16}
PACKAGE_NAME=postgresql
PACKAGE_URL=https://github.com/bitnami/containers

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

yum install git -y 

# Install docker if not found
if ! [ $(command -v docker) ]; then
        sudo yum install -y docker
fi

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd containers
git checkout $PACKAGE_VERSION
cd bitnami/$PACKAGE_NAME/14/debian-11

git apply $SCRIPT_DIR/postgresql-bv_14.10.0.patch

docker build -t postgresql-bv:14.10.0 .
