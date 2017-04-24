# ----------------------------------------------------------------------------
#
# Package	: karyon
# Version	: 3.0.1-rc.25
# Source repo	: https://github.com/Netflix/karyon
# Tested on	: ubuntu_16.04
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
sudo apt-get update -y
sudo apt-get install -y git gradle openjdk-8-jdk openjdk-8-jre

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

# Build code.
git clone https://github.com/Netflix/karyon
cd karyon
./buildViaTravis.sh
./installViaTravis.sh
