# -----------------------------------------------------------------------------
#
# Package       : airline
# Version       : 0.6
# Source repo   : https://github.com/airlift/airline.git
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
VERSION=${1:-0.6}
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)')
echo "JAVA_HOME is $JAVA_HOME"
# update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin

#clone the repo.
git clone  https://github.com/airlift/airline.git
cd airline/
git checkout $VERSION

#build  and test the package
mvn install
