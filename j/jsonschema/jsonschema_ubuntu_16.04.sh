# ----------------------------------------------------------------------------
#
# Package       : Jackson Module JsonSchema 
# Version       : 2.9.4
# Source repo   : https://github.com/FasterXML/jackson-module-jsonSchema
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install Dependencies 
sudo apt-get update -y && sudo apt-get install -y maven openjdk-8-jdk git

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

#Clone and install pre-req jackson-parent package
git clone https://github.com/FasterXML/jackson-parent
cd jackson-parent
mvn install
cd ..

# Clone the source for jsckson-module-jsonSchema and build it 
git clone https://github.com/FasterXML/jackson-module-jsonSchema 
cd jackson-module-jsonSchema
mvn install -DskipTests=true -Dmaven.javadoc.skip=true -B -V && \
mvn test -B
