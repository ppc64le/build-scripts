# ----------------------------------------------------------------------------
#
# Package       : hibernate-core
# Version       : 5.2.0 Latest
# Source repo   : https://github.com/hibernate/hibernate-orm.git
# Tested on     : RHEL8
# Script License: Apache License, Version 2 or later
# Maintainer    : Narasimha udala <narasimha.rao.udala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

yum update -y
yum install git -y

yum install java-1.8.0-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.292.b10-1.el8_4.ppc64le
export PATH=$PATH:$JAVA_HOME/bin
git clone https://github.com/hibernate/hibernate-orm.git

cd hibernate-orm
./gradlew

./gradle hibernate-core:test


