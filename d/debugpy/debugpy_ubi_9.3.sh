#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : debugpy
# Version        : v1.5.1
# Source repo    : https://github.com/microsoft/debugpy.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : vivek sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=debugpy
PACKAGE_VERSION=${1:-v1.5.1}
PACKAGE_URL=https://github.com/microsoft/debugpy.git

# Install necessary system packages
yum install -y git gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel python-devel

# Clone the repository
git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}

# Install pytest and other dependencies
pip install debugpy pytest pytest-timeout psutil requests pytest-xdist 
pip install .

# Build the package
if ! python3 setup.py build; then
    echo "------------------$PACKAGE_NAME: Build fails -------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_Fails"
    exit 1
fi

# Run tests
if ! pytest --ignore=tests/debugpy/test_run.py --ignore=test/debugpy/test_gevent.py --ignore=test/debugpy/test_django.py --ignore=tests/debugpy/test_exception.py --ignore=tests/debugpy/test_input.py --ignore=tests/debugpy/test_log.py --ignore=tests/debugpy/test_flask.py --ignore=tests/debugpy/test_output.py --ignore=tests/debugpy/test_args.py --ignore=tests/debugpy/test_attach.py; then  
    echo "------------------$PACKAGE_NAME: Tests_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi

