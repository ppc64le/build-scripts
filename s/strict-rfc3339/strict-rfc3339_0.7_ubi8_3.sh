# ----------------------------------------------------------------------------
#
# Package       : strict-rfc3339
# Version       : version-0.7
# Source repo   : https://github.com/danielrichman/strict-rfc3339
# Tested on     : ubi 8.3
# Script License: GPL v3
# Maintainer    : Varsha Aaynure <Varsha.Aaynure@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
#
# ----------------------------------------------------------------------------
set -ex

PACKAGE_VERSION=version-0.7
echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is version-0.7"
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

PACKAGE_NAME=strict-rfc3339
PACKAGE_URL=https://github.com/danielrichman/strict-rfc3339.git

#Install required files
yum update -y && yum install -y python3 git 
pip3 install pytest

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build package
python3 setup.py install

#Test package 
pytest
