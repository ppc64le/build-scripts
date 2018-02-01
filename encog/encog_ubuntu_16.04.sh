# ----------------------------------------------------------------------------
#
# Package	: encog
# Version	: 3.4
# Source repo	: https://github.com/encog
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
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
sudo apt-get update -y build-essential default-jdk git maven

export TERM=dumb
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
export PATH=$JAVA_HOME/bin:$PATH
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"

mkdir -p ~/.gradle && echo "org.gradle.daemon=false" >> ~/.gradle/gradle.properties

#Build encog-c. The repository does not have any test cases
git clone https://github.com/encog/encog-c
cd encog-c
make ARCH=64

#Build and validate encog-java-examples. 
cd $HOME
git clone https://github.com/encog/encog-java-examples
cd encog-java-examples
./gradlew assemble
./gradlew check

#Build and validate encog-java-workbench
cd $HOME
git clone https://github.com/encog/encog-java-workbench
cd encog-java-workbench
./gradlew assemble
./gradlew check

#Build and validate encog-java-core
cd $HOME
git clone https://github.com/encog/encog-java-core.git
cd encog-java-core
./gradlew assemble
./gradlew check

