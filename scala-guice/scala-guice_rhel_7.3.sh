# ----------------------------------------------------------------------------
#
# Package	: scala-guice
# Version	: 4.1.0
# Source repo	: https://github.com/codingwell/scala-guice.git
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
curl https://bintray.com/sbt/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
sudo yum update -y
sudo yum install -y git gcc wget make python tar curl \
    java-1.7.0-openjdk-devel.ppc64le sbt

export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
export PATH=$JAVA_HOMEbin:$PATH

# Clone and build source code.
git clone https://github.com/codingwell/scala-guice.git
cd scala-guice
sbt compile
sbt test
