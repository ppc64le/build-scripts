# -----------------------------------------------------------------------------
#
# Package	: jamm
# Version	: v0.3.0
# Source repo	: https://github.com/jbellis/jamm.git
# Tested on	:ubi8.4
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
PACKAGE_VERSION="v0.3.0"
PACKAGE_URL="https://github.com/jbellis/jamm.git"
APACHE_ANT_VERSION="1.9.4"

#update location of patch if required
PATCH_PATH="/build-scripts/j/jamm/jamm-v0.3.0.patch"

#install dependencies
yum install  -y java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless gcc-c++ wget unzip

mkdir -p /home/tester
cd /home/tester

#download and install ANT
wget https://archive.apache.org/dist/ant/binaries/binaries/apache-ant-$APACHE_ANT_VERSION-bin.zip 
unzip apache-ant-$APACHE_ANT_VERSION-bin.zip 
rm -f apache-ant-$APACHE_ANT_VERSION-bin.zip 

ANT_HOME=/home/tester/apache-ant-$APACHE_ANT_VERSION
PATH=$PATH:$ANT_HOME/bin

#clone jamm
git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout tags/$PACKAGE_VERSION
git apply $PATCH_PATH

#build jamm
ant jar 

#test 
ant test 

exit 0
