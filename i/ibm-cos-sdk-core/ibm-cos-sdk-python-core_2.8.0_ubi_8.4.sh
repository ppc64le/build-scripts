# -----------------------------------------------------------------------------
#
# Package	: ibm-cos-sdk-python-core
# Version	: 2.8.0
# Source repo	: https://github.com/IBM/ibm-cos-sdk-python-core
# Tested on	: UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ibm-cos-sdk-python-core
PACKAGE_VERSION=2.8.0
PACKAGE_URL=https://github.com/IBM/ibm-cos-sdk-python-core/

yum install -y python38 procps-ng git

# Install dependencies
pip3 install tox

git clone $PACKAGE_URL $PACKAGE_NAME

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

echo 'python-dateutil>=2.8.2' >> requirements.txt

# 1 Error in parity with x86: AttributeError: 'S3' object has no attribute 'get_bucket_lifecycle'
tox -e py38