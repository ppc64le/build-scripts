#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : graphql-engine 
# Version       : v2.48.14
# Source repo   : https://github.com/hasura/graphql-engine.git
# Tested on     : Fedora 42 (ppc64le)
# Language      : GHC (Haskell)
# Ci-Check      : false
# Script License: Apache License, Version 2 or later
# Maintainer    : Pratik Tonage <Pratik.Tonage@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
SCRIPT_PACKAGE_VERSION=v2.48.14
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_NAME="graphql-engine"
PACKAGE_ORG="hasura"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
GHC_VERSION=9.10.3
CABAL_VERSION=3.12.1.0
SCRIPT_PATH=$(dirname $(realpath $0))
BUILD_HOME="$(pwd)"

# Install dependencies
dnf install git g++ gcc-c++ cabal-install libpq-devel unixODBC-devel zlib-devel ghc9.10 libstdc++ -y

# Install required version of cabal-install
cabal user-config init
sed -i 's|url: http://hackage.haskell.org/|url: https://hackage.haskell.org/|' $HOME/.config/cabal/config
cabal update
cabal install cabal-install-$CABAL_VERSION --overwrite-policy=always
export PATH="$HOME/.local/bin/:$PATH"
cabal -V
cabal update
dnf -y remove ghc cabal-install

cd "${BUILD_HOME}"
# ---------------------------
# Clone and Prepare Repository
# ---------------------------
git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# Apply patch if present
PATCH_FILE="$SCRIPT_PATH/$PACKAGE_NAME-$PACKAGE_VERSION.patch"
if [ -f "$PATCH_FILE" ]; then
    git apply "$PATCH_FILE"
fi

echo $PACKAGE_VERSION > "$(git rev-parse --show-toplevel)/server/CURRENT_VERSION"
rm -f cabal.project.freeze

# ---------------------------
# Build
# ---------------------------
ret=0
cabal build exe:graphql-engine || ret=$?
if [ $ret -ne 0 ]; then
    set +ex
    echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
    exit 1
fi
export GRAPHQL_BIN=$BUILD_HOME/$PACKAGE_NAME/dist-newstyle/build/ppc64le-linux/ghc-$GHC_VERSION/graphql-engine-1.0.0/x/graphql-engine/opt/build/graphql-engine/graphql-engine

#Smoke test
if ! $GRAPHQL_BIN version; then
    echo "Smoke test failed"
    exit 2
fi

# ---------------------------
# Unit Tests
# ---------------------------
make test-unit || ret=$?
if [ $ret -ne 0 ]; then
    set +ex
    echo "------------------ ${PACKAGE_NAME}: Test Failed ------------------"
    exit 3
fi

# Generate cabal.project.freeze to lock exact dependency versions (optional)
cabal freeze

echo "$PACKAGE_NAME build and unit tests successful!"
echo "Binary available at $GRAPHQL_BIN

