#!/bin/bash -e
#--------------------------------------------------------------------------------
# Package       : kroxylicious
# Version       : v.0.11.0
# Source repo   : https://github.com/kroxylicious/kroxylicious
# Tested on     : UBI 9.3
# Language      : Java
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vaibhav Nazare <Vaibhav.Nazare@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -------------------------------------------------------------------------------

#Variables
PACKAGE_NAME=kroxylicious
PACKAGE_VERSION=${1:-v0.11.0}
PACKAGE_URL=https://github.com/kroxylicious/kroxylicious
 
yum update -y
yum install -y -q openssl-devel
yum install -y java-21-openjdk-devel git
echo 'export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
 
yum install -y maven
 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Build package
echo "---------------------Building the package------------------------------------------"
if ! mvn clean verify -pl '!kroxylicious-kms-provider-aws-kms-test-support, !kroxylicious-kms-provider-hashicorp-vault-test-support, !kroxylicious-kms-provider-hashicorp-vault' -DskipSTs=true -DskipITs=true ; then
    echo "------------------$PACKAGE_NAME-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail "
    exit 1;
fi
