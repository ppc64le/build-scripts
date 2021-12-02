# -----------------------------------------------------------------------------
#
# Package	: jamm
# Version	: 6a0a13f
# Source repo	: https://github.com/jbellis/jamm.git
# Tested on	: ubi8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar {Sapana.Khemkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e

PACKAGE_NAME="jamm"
PACKAGE_VERSION="6a0a13f"
PACKAGE_URL="https://github.com/jbellis/jamm.git"
APACHE_ANT_VERSION="1.10.12"

#install dependencies
yum install  -y java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless  

mkdir -p /home/tester
cd /home/tester

#clone jamm
git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#build + test jamm
./gradlew jar test

exit 0
