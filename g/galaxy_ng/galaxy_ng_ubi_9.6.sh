#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : galaxy_ng
# Version          : 4.10.6
# Source repo      : https://github.com/ansible/galaxy_ng.git
# Tested on        : UBI 9.6
# Language         : Python
# Ci-Check         : True
# Script License   : GPL-2.0 license
# Maintainer       : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=galaxy_ng
PACKAGE_VERSION=${1:-4.10.6}
PACKAGE_URL=https://github.com/ansible/galaxy_ng.git

yum install -y wget gcc-toolset-13 gcc-toolset-13-gcc-c++ git make  python3.12 python3.12-devel python3.12-pip  openssl-devel openldap-devel  zlib-devel libjpeg-turbo-devel rust cargo

git clone $PACKAGE_URL $PACKAGE_NAME
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

python3.12 -m pip install --prefer-binary grpcio==1.71.0 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux

if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Install_Success"
    exit 0
fi

# NOTE:
# Tests are skipped because galaxy_ng requires a full runtime stack (Django, PostgreSQL,
# Redis, Celery, and Pulp services) which is not available in this minimal build environment.

