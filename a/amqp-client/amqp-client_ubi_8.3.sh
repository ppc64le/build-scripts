# -----------------------------------------------------------------------------
#
# Package       : amqp-client
# Version       : v5.14.0
# Source repo   : https://github.com/rabbitmq/rabbitmq-java-client.git
# Tested on     : UBI 8.3
# Language      : Java
# Travis-Check  : True
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

#!/bin/bash

set -e

PACKAGE_NAME=rabbitmq-java-client
PACKAGE_VERSION=${1:-v5.14.0}
PACKAGE_URL=https://github.com/rabbitmq/rabbitmq-java-client.git
PACKAGE_SUPPORTED=https://github.com/rabbitmq/rabbitmq-codegen.git
yum install -y python2 git maven make

ln -s /usr/bin/python2 /usr/bin/python

#clone the repo.
git clone $PACKAGE_SUPPORTED
git clone $PACKAGE_URL

cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

#dependency and build  and test the package
#Note: Test is failing on both Power and Intel VMs.
make deps
./mvnw clean install -Ddeps.dir=./deps -DskipTests

./mvnw clean test -Ddeps.dir=./deps
