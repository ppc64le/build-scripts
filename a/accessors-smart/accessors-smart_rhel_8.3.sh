# -----------------------------------------------------------------------------
#
# Package       : accessors-smart
# Version       : v2.3
# Source repo   : https://github.com/netplex/json-smart-v2.git
# Tested on     : UBI 8
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
yum update -y
yum -y install git maven java-1.8.0-openjdk.ppc64le java-1.8.0-openjdk-devel.ppc64le
VERSION=${1:-v2.3}
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)')
echo "JAVA_HOME is $JAVA_HOME"
# update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin

#clone the repo.
git clone https://github.com/netplex/json-smart-v2.git
cd json-smart-v2/
git checkout $VERSION

cd accessors-smart/

#build package
mvn install -DskipTests=true

#build and test the package 
#Note: Test related to DateFormat for Japanese locale is failing on both Power and Intel.
mvn install
