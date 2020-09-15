# ----------------------------------------------------------------------------
#
# Package       : narayana-spring-boot
# Version       : 2.1.2-SNAPSHOT
# Source repo   : https://github.com/snowdrop/narayana-spring-boot
# Tested on     : rhel_7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Shirodkar <amit.shirodkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install the required dependencies
yum -y update && yum install -y git vim java-1.8.0-openjdk-devel

# download src
git clone https://github.com/snowdrop/narayana-spring-boot.git

#build
cd narayana-spring-boot
./mvnw clean install


