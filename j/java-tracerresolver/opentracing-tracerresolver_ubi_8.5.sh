# ----------------------------------------------------------------------------
#
# Package       : opentracing-tracerresolver
# Version       : 0.1.8
# Source repo   : https://github.com/opentracing-contrib/java-tracerresolver
# Tested on     : UBI: 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -e 

PACKAGE_NAME=opentracing-tracerresolver
PACKAGE_VERSION=${1:-0.1.8}              
PACKAGE_URL=https://github.com/opentracing-contrib/java-tracerresolver

# install dependencies
yum install -y git maven

# clone package
git clone $PACKAGE_URL
cd java-tracerresolver
git checkout $PACKAGE_VERSION

# to build & test
./mvnw install -Dmaven.javadoc.skip=true -B -V