# ----------------------------------------------------------------------------
#
# Package       : opentracing-contrib/java-spring-web
# Version       : 2.1.4-SNAPSHOT
# Source repo   : https://github.com/opentracing-contrib/java-spring-web
# Tested on     : rhel_7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Shirodkar <amit.shirodkar@ibm.com>
#
# Disclaimer: This script has been tested as root on the given
# ==========  platform using pacakge versions as listed.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such a case, please
#             contact the "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install the required dependencies
yum -y update
yum install -y which git java-1.8.0-openjdk-devel

# download src
git clone https://github.com/opentracing-contrib/java-spring-web.git

#build
cd java-spring-web
./mvnw clean install

