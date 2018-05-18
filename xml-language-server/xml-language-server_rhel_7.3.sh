# ----------------------------------------------------------------------------
#
# Package       : XML-language-server
# Version       : NA
# Source repo   : https://github.com/microclimate-devops/xml-language-server.git
# Tested on     : RHEL 7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum -y update
sudo yum -y install git java-1.8.0-openjdk-devel.ppc64le
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
git clone https://github.com/microclimate-devops/xml-language-server.git
cd xml-language-server/server/xml-server
./mvnw clean package

#NOTE: No Tests Found
