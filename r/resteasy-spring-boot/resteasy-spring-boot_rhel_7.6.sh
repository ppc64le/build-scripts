# ----------------------------------------------------------------------------
#
# Package       : resteasy-spring-boot
# Version       : 4.2.0.Final-SNAPSHOT
# Source repo   : https://github.com/resteasy/resteasy-spring-boot
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

WDIR=`pwd`

#Install the required dependencies
yum -y update && yum install -y git wget vim java-1.8.0-openjdk-devel

# download apache-maven 
wget https://archive.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz 
tar -xvzf apache-maven-3.6.2-bin.tar.gz
export PATH=$WDIR/apache-maven-3.6.2/bin:$PATH 

# download src
git clone https://github.com/resteasy/resteasy-spring-boot.git

#build
cd resteasy-spring-boot
mvn clean install
