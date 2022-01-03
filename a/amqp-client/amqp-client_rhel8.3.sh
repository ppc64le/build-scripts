# -----------------------------------------------------------------------------
#
# Package       : amqp-client
# Version       : v4.8.3
# Source repo   : https://github.com/rabbitmq/rabbitmq-java-client.git
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
yum -y install make python2 git maven java-1.8.0-openjdk.ppc64le java-1.8.0-openjdk-devel.ppc64le
VERSION=${1:-v4.8.3}
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-)(?=.*ppc64le)')
echo "JAVA_HOME is $JAVA_HOME"
# update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin

ln -s usr/bin/python2 usr/bin/python

#clone the repo.
git clone https://github.com/rabbitmq/rabbitmq-java-client.git
git clone https://github.com/rabbitmq/rabbitmq-codegen.git

cd rabbitmq-java-client/
#git checkout $VERSION

#dependency and build  and test the package
make deps
./mvnw clean install -Ddeps.dir=./deps -DskipTests

./mvnw clean test -Ddeps.dir=./deps
