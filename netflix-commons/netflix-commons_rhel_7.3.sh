# ----------------------------------------------------------------------------
#
# Package	: netflix-commons
# Version	: 0.3.0
# Source repo	: https://github.com/Netflix/netflix-commons.git
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
sudo yum install -y git java-1.8.0-openjdk java-1.8.0-openjdk-devel
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$PATH:$JAVA_HOME/bin

# Clone and build source code.
git clone https://github.com/Netflix/netflix-commons.git
cd netflix-commons
./gradlew
./gradlew test
