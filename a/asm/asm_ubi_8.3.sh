# ----------------------------------------------------------------------------
#
# Package       : asm-analysis and asm-util
# Version       : ASM_9_2
# Source repo   : https://gitlab.ow2.org/asm/asm
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Variables
REPO=https://gitlab.ow2.org/asm/asm

# Default tag for asm
if [ -z "$1" ]; then
  export VERSION="ASM_9_2"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git wget unzip 

# install java
yum install -y java-11-openjdk-devel

# install gradle
wget https://services.gradle.org/distributions/gradle-6.7.1-bin.zip
unzip gradle-6.7.1-bin.zip
mkdir /opt/gradle
cp -pr gradle-6.7.1/* /opt/gradle
export PATH=/opt/gradle/bin:${PATH}

#Cloning Repo
git clone $REPO
cd asm
git checkout ${VERSION}

#Build and test package
gradle build
gradle test jacocoTestCoverageVerification







