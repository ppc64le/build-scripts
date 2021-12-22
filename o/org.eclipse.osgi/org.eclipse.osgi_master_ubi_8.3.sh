# ---------------------------------------------------------------------
#
# Package       : org.eclipse.osgi
# Version       : master
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

#!/bin/bash

#install dependencies
yum install -y wget git java-11-openjdk java-11-openjdk-devel
cd /opt
wget https://dlcdn.apache.org/maven/maven-3/3.8.3/binaries/apache-maven-3.8.3-bin.tar.gz
tar xzvf apache-maven-3.8.3-bin.tar.gz
export PATH=/opt/apache-maven-3.8.3/bin:$PATH

#get and build sources
git clone -b master --recursive https://git.eclipse.org/r/equinox/rt.equinox.framework.git
cd rt.equinox.framework/
git pull --recurse-submodules
git submodule update
cd bundles/org.eclipse.osgi
mvn -Pbuild-individual-bundles clean verify
mvn test

#conclude
find -name *.jar
echo "Complete!"
