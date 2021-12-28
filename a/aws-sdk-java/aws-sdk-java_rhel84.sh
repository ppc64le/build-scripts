# -----------------------------------------------------------------------------
#
# Package	: aws-sdk-java
# Version	: 1.7.3
# Source repo	: https://github.com/aws/aws-sdk-java
# Tested on	: RHEL 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Gajanan Kulkarni <gajanan.kulkarni@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


export PACKAGE_NAME=aws-sdk-java
export PACKAGE_VERSION=1.7.3
export PACKAGE_URL=https://github.com/aws/aws-sdk-java.git


git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}
yum install maven -y
mvn clean install -Dgpg.skip=true
