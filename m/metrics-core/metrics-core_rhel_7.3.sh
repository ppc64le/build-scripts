# ----------------------------------------------------------------------------
#
# Package	: metrics-core
# Version	: 3.2.2
# Source repo	: https://github.com/dropwizard/metrics.git
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
sudo yum install -y git gcc wget make python tar \
    java-1.8.0-openjdk-devel.ppc64le

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Install maven.
wget http://archive.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz
tar -zxf apache-maven-3.2.5-bin.tar.gz
sudo cp -R apache-maven-3.2.5 /usr/local
sudo ln -s /usr/local/apache-maven-3.2.5/bin/mvn /usr/bin/mvn

# Clone and build source code.
git clone https://github.com/dropwizard/metrics.git
cd metrics
mvn verify
