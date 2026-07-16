#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package           : asyncpg
# Version           : v0.31.0
# Source repo       : https://github.com/MagicStack/asyncpg.git
# Tested on         : UBI:9.6
# Language          : Python
# Ci-Check          : True
# Script License    : Apache License, Version 2 or later
# Maintainer        : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=asyncpg
PACKAGE_VERSION=${1:-v0.31.0}
PACKAGE_URL=https://github.com/MagicStack/asyncpg.git

# Install base system dependencies
dnf install -y git gcc python3.13 python3.13-pip python3.13-devel make
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
dnf install -y --nogpgcheck postgresql16-server postgresql16-libs postgresql16-contrib


export PATH="/usr/pgsql-16/bin:$PATH"

python3.13 -m pip install --upgrade pip
python3.13 -m pip install "setuptools<80" wheel "Cython>=3.2.1,<4.0.0" pytest distro

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
# asyncpg/pgproto is a git submodule — must be fetched before building
git submodule update --init --recursive

if ! python3.13 -m pip install --no-build-isolation ".[dev]"; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi


TESTS_DIR="$(pwd)/tests"
useradd -m pguser 2>/dev/null || true
chown -R pguser "$(pwd)"
cd /
if ! su pguser -c "PATH=$PATH python3.13 -m pytest '$TESTS_DIR' -x -p no:cacheprovider"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Install_and_Test_Success"
    exit 0
fi