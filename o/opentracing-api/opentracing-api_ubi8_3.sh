# ----------------------------------------------------------------------------
#
# Package       : opentracing-api   
# Version       : 0.33.0
# Language      : Java
# Source repo   : https://github.com/opentracing/opentracing-java
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
PACKAGE_URL=https://github.com/opentracing/opentracing-java.git
PACKAGE_VERSION="${1:-0.33.0}"

#Install required files
yum install -y git maven

#Cloning Repo
git clone $PACKAGE_URL
cd opentracing-java/opentracing-api/
git checkout $PACKAGE_VERSION

#Build and test package
mvn install

echo "Complete!"