#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package         : jackson-dataformat-csv
# Version         : jackson-dataformats-text-2.10.5, jackson-dataformats-text-2.11.0
# Language        : Java
# Source repo     : https://github.com/FasterXML/jackson-dataformats-text
# Tested on       : UBI 8.3
# Language        : Java
# Travis-Check    : True
# Script License  : Apache-2.0 License    
# Maintainer      : Varsha Aaynure <Varsha.Aaynure@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#Variables
PACKAGE_NAME=jackson-dataformats-text
PACKAGE_URL=https://github.com/FasterXML/jackson-dataformats-text.git
PACKAGE_VERSION=jackson-dataformats-text-2.10.5

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is jackson-dataformats-text-2.10.5, not all versions are supported."
PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#Install required files
yum install -y git maven

#Cloning Repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build test package
mvn install 

echo "Complete!"