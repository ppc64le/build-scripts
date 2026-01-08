    #!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : vert.x
# Version       : 5.0.0
# Source repo   : https://github.com/eclipse-vertx/vert.x
# Tested on     : UBI 9.6
# Language      : JAVA
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Karanam Santhosh <Karanam.Santhosh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=vert.x
PACKAGE_VERSION=${1:-5.0.0}
PACKAGE_URL=https://github.com/eclipse-vertx/vert.x.git

yum update -y
yum install git wget  gcc gcc-c++ -y
yum install openssl-devel -y
yum install java-17-openjdk java-17-openjdk-devel -y
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH=$JAVA_HOME/bin:$PATH

dnf -y install maven

if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
fi

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

if ! mvn package -DskipTests; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 1
fi

if ! mvn test -Dtest='!FileSystemTest#testChownToRootFails'; then
    echo "------------------$PACKAGE_NAME:build_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 2
fi

#tests failing due to netty issue refer links for the same -
#https://github.com/netty/netty-tcnative/issues/531
#https://github.com/eclipse-vertx/vert.x/issues/4227
#https://github.com/netty/netty/issues/12432
