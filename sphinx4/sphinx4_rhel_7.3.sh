# ----------------------------------------------------------------------------
#
# Package	: sphinx4
# Version	: n/a
# Source repo	: https://github.com/cmusphinx/sphinx4
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
sudo yum install -y wget unzip git java-1.7.0-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk

# Install gradle.
WDIR=`pwd`
wget https://services.gradle.org/distributions/gradle-2.10-bin.zip
unzip gradle-2.10-bin.zip

export PATH=$PATH:$WDIR/gradle-2.10/bin:$JAVA_HOME/bin

# Clone and build source code.
git clone https://github.com/cmusphinx/sphinx4
cd sphinx4
gradle build
gradle test
