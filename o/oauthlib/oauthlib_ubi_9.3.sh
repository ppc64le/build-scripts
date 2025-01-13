#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : oauthlib
# Version        : v3.2.2
# Source repo    : https://github.com/oauthlib/oauthlib.git
# Tested on      : UBI 9.3
# Language       : Python
# Travis-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=oauthlib
PACKAGE_VERSION=${1:-v3.2.2}
PACKAGE_URL=https://github.com/oauthlib/oauthlib.git

# Install necessary system packages
yum install -y git gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel python-devel

# Clone the repository
git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}
git checkout v${PACKAGE_VERSION}

# Install the package
pip3 install .

# Install test dependencies
pip3 install pytest PyJWT cryptography blinker

# Run tests(skipping the some testcase as sha1 is not supported by this backend for RSA signing)
if ! pytest -k "not (test_rsa_signature or test_rsa_method or test_rsa_bad_keys or test_rsa_false_positives or test_rsa_jwt_algorithm_cache or test_sign_rsa_sha1_with_client)"; then
    echo "------------------$PACKAGE_NAME: Tests_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 1
else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
