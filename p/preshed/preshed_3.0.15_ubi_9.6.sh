#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : preshed
# Version          : release-v3.0.15
# Source repo      : https://github.com/explosion/preshed.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# Variables
PACKAGE_NAME=preshed
PACKAGE_VERSION=${1:-release-v3.0.15}
PACKAGE_URL=https://github.com/explosion/preshed.git
PACKAGE_DIR=preshed
CURRENT_DIR="${PWD}"

# Upstream 3.x tags look like 'release-v3.0.15'; accept '3.0.15', 'v3.0.15' or the full tag
VERSION_NUM="${PACKAGE_VERSION#release-}"
VERSION_NUM="${VERSION_NUM#v}"
TAG="release-v${VERSION_NUM}"

# Install dependencies
yum install -y git gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ make \
    python3.12 python3.12-devel python3.12-pip

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:${LD_LIBRARY_PATH:-}

# pyproject.toml requires cython>=3.1 plus cymem/murmurhash (cimported at build time)
python3.12 -m pip install --upgrade pip setuptools wheel pytest "cython>=3.1" \
    "cymem>=2.0.2,<2.1.0" "murmurhash>=0.28.0,<1.1.0"

# Clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout "$TAG"

if ! python3.12 -m pip install . --no-build-isolation; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run the packaged tests (preshed/tests) against the installed build,
# from outside the source tree so the unbuilt source package is not imported.
cd "$CURRENT_DIR"

if ! python3.12 -m pytest --pyargs preshed -v -p no:cacheprovider; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
