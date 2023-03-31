#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : gitea
# Version       : v1.17.2
# Source repo   : https://github.com/go-gitea/gitea
# Tested on     : Red Hat Enterprise Linux 8.2 (Ootpa)
# Language      : GO
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Reynold Vaz <Reynold.Vaz@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_VERSION=${1:-v1.17.2}
PACKAGE_NAME=gitea
PACKAGE_URL=https://github.com/go-gitea/gitea.git

# Install docker if not found
if ! [ $(command -v docker) ]; then
        sudo yum install -y docker
fi

# Install git if not found
if ! [ $(command -v git) ]; then
        sudo yum install -y git
fi

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#harden step
sed -i '30iRUN apk --upgrade --no-cache add expat' Dockerfile

docker build --rm -t ibmcom/gitea-ppc64le:$PACKAGE_VERSION .
