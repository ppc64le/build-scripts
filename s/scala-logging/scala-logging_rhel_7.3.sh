# ----------------------------------------------------------------------------
#
# Package	: scala-logging
# Version	: 3.5.0
# Source repo	: https://github.com/typesafehub/scala-logging
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install dependencies.
sudo yum update -y
sudo yum install -y curl
curl https://bintray.com/sbt/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
sudo yum update -y
sudo yum install -y git gcc make python java-1.7.0-openjdk-devel.ppc64le sbt

export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Clone and build source code.
git clone https://github.com/typesafehub/scala-logging
cd scala-logging
sbt compile
sbt test
