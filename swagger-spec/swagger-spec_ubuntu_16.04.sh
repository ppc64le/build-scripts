# ----------------------------------------------------------------------------
#
# Package	: swagger-spec
# Version	: 3.0.0-rc2
# Source repo	: https://github.com/swagger-api/swagger-spec.git
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
sudo apt-get install -y dirmngr
echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
sudo apt-get install -y apt-transport-https
sudo apt-get update -y
sudo apt-get install -y nodejs npm sbt git openjdk-8-jdk openjdk-8-jre
sudo ln -s /usr/bin/nodejs /usr/bin/node

# Clone and build source code.
git clone --depth=50 --branch=master https://github.com/swagger-api/swagger-spec.git
cd swagger-spec
npm install
npm test
