# ----------------------------------------------------------------------------
#
# Package       : jaeger-core
# Version       : v1.3.2
# Language      : Java
# Source repo   : https://github.com/jaegertracing/jaeger-client-java
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
PACKAGE_URL=https://github.com/jaegertracing/jaeger-client-java.git
PACKAGE_VERSION="${1:-v1.3.2}"

#Install required files
sudo yum install -y git java-1.8.0-openjdk-devel

#Cloning Repo
git clone $PACKAGE_URL
cd jaeger-client-java/jaeger-core/
git checkout $PACKAGE_VERSION

#Build and test package
../gradlew build
../gradlew test 

echo "Complete!"