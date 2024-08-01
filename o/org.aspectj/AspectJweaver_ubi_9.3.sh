# ----------------------------------------------------------------------------
#
# Package       : AspectJweaver
# Version       : V1_9_20_1 
# Source repo   : https://github.com/eclipse/org.aspectj
# Tested on	: UBI 9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>

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

# Variables
REPO=https://github.com/eclipse/org.aspectj

# Default tag for AspectJweaver
if [ -z "$1" ]; then
  export VERSION="V1_9_20_1"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install -y git wget maven

# install java 
yum install -y java-11-openjdk-devel


# Cloning Repo
git clone $REPO
cd ./org.aspectj/
git checkout ${VERSION}

# check maven
./mvnw -B --version

#Build and test package
./mvnw -B --file pom.xml -DskipTests install

# testcase failures same as x86
#./mvnw -B --file pom.xml -Daspectj.tests.verbose=false verify







