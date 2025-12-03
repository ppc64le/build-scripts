#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : graphql-engine 
# Version       : 2.45.2
# Source repo   : https://github.com/hasura/graphql-engine.git
# Tested on     : Fedora 42 (ppc64le)
# Language      : GHC (Haskell)
# Ci-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=v2.45.2
PACKAGE_NAME=graphql-engine
PACKAGE_ORG=hasura
GHC_VERSION=9.10.1
CABAL_VERSION=3.12.1.0
SCRIPT_PATH=$(dirname $(realpath $0))
WDIR=$(pwd)

#Install deps
yum install git g++ cabal-install libpq-devel unixODBC-devel zlib-devel -y
yum config-manager addrepo --set=baseurl=https://rpmfind.net/linux/fedora-secondary/releases/42/Everything/ppc64le/os
yum install -y https://www.rpmfind.net/linux/fedora-secondary/releases/42/Everything/ppc64le/os/Packages/g/ghc9.10-devel-9.10.1-7.fc42.ppc64le.rpm \
               https://www.rpmfind.net/linux/fedora-secondary/releases/42/Everything/ppc64le/os/Packages/g/ghc9.10-9.10.1-7.fc42.ppc64le.rpm
cabal update
cabal install cabal-install-$CABAL_VERSION --overwrite-policy=always
export PATH="$HOME/.local/bin/:$PATH"
cabal -V
cabal update
yum -y remove ghc cabal-install

#Get code and build
git clone https://github.com/$PACKAGE_ORG/$PACKAGE_NAME.git
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply $SCRIPT_PATH/$PACKAGE_NAME-$PACKAGE_VERSION.patch
echo $PACKAGE_VERSION > "$(git rev-parse --show-toplevel)/server/CURRENT_VERSION"
cabal build exe:graphql-engine
export GRAPHQL_BIN=$WDIR/$PACKAGE_NAME/dist-newstyle/build/ppc64le-linux/ghc-$GHC_VERSION/graphql-engine-1.0.0/x/graphql-engine/opt/build/graphql-engine/graphql-engine

#Smoke test
$GRAPHQL_BIN version

#Unit Tests
make test-unit

echo "$PACKAGE_NAME build and unit tests successful!"
echo "Binary available at $GRAPHQL_BIN

