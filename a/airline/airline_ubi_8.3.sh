# -----------------------------------------------------------------------------
#
# Package       : airline
# Version       : 0.6
# Source repo   : https://github.com/airlift/airline.git
# Tested on     : UBI 8.3
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju.Sah@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
PACKAGE_NAME=airline
PACKAGE_VERSION=${1:-0.6}
PACKAGE_URL=https://github.com/airlift/airline.git

yum install -y git maven java-1.8.0-openjdk.ppc64le java-1.8.0-openjdk-devel.ppc64le

export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)')
echo "JAVA_HOME is $JAVA_HOME"
#Update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin

#Clone the repo.
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#Build and test the package
mvn install

