# ----------------------------------------------------------------------------
#
# Package	: javax-inject
# Version	: 4.0.0 
# Source repo	: https://github.com/javax-inject/javax-inject 
# Tested on	: ubuntu_20.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Gururaj R Katti <Gururaj.Katti@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update
sudo apt-get install openjdk-8-jdk wget git -y
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el/

wget http://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzvf apache-maven-3.6.3-bin.tar.gz
export PATH=$PATH:`pwd`/apache-maven-3.6.3/bin
git clone https://github.com/javax-inject/javax-inject
## Build and test javax-inject
cd javax-inject
sed 's/1.5/1.8/g' pom.xml >tmp
mv tmp pom.xml
mvn clean install
