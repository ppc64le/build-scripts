# ----------------------------------------------------------------------------
#
# Package       : jackson-dataformat-csv
# Version       : jackson-dataformats-text-2.10.5
# Language      : Java
# Source repo   : https://github.com/FasterXML/jackson-dataformats-text
# Tested on     : UBI 8.3
# Script License: Apache-2.0 License    
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

#Variables
PACKAGE_URL=https://github.com/FasterXML/jackson-dataformats-text.git
PACKAGE_VERSION=${1:-jackson-dataformats-text-2.10.5}

#Install required files
yum install -y git maven

#Cloning Repo
git clone $PACKAGE_URL
cd jackson-dataformats-text/
git checkout $PACKAGE_VERSION

#Build test package
mvn install 

echo "Complete!"