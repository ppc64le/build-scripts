# ----------------------------------------------------------------------------
#
# Package	: appsody/stacks/incubator/java-microprofile
# Version	: latest (0.9.0)
# Source repo	: https://github.com/appsody/stacks/tree/master/incubator/java-microprofile
# Tested on	: rhel_7.6
# Script License: Apache License, Version 2.0
# Maintainer	: Vrushali Inamdar <vrushali.inamdar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# ----------------------------------------------------------------------------
# Prerequisites:
#
# Docker Version 18.03.1-ce is installed and running
# Build docker image "adoptopenjdk/openjdk8-openj9-ubi" using the docker file - Dockerfile.openj9.releases.full (cloned from https://github.com/AdoptOpenJDK/openjdk-docker/blob/6ef982afbdd32a0b2195c9ee0fa36328535a3c64/8/jdk/ubi/Dockerfile.openj9.releases.full)
# Build docker image "open-liberty:19.0.0.12-kernel-java8-openj9-ubi" using the docker file - Dockerfile.ubi.adoptopenjdk8 ( cloned from https://github.com/OpenLiberty/ci.docker/blob/7c7bef891fdf69ec74a2f63cbd1354adb5eb16c7/releases/19.0.0.12/kernel/Dockerfile.ubi.adoptopenjdk8 )
#
# Dockerfile-stack and Dockerfile are copied to the current directory of this build script
#
# appsody version 0.5.8 or greater is available in path 
# ----------------------------------------------------------------------------

export APPSODY_STACKS_VERSION=""

wrkdir=`pwd`

docker build -f Dockerfile.openj9.releases.full -t adoptopenjdk/openjdk8-openj9-ubi .

docker build -f Dockerfile.ubi.adoptopenjdk8 -t open-liberty:19.0.0.12-kernel-java8-openj9-ubi .

# NOTE :: Make sure that above 2 commands have successfully generated the docker images

# get the source code for stacks repo
git clone https://github.com/appsody/stacks.git
cd stacks

if [ "$APPSODY_STACKS_VERSION" == "" ]
then
   echo "No specific version specified. Using latest ..."
else
   echo "Building the specified version $APPSODY_STACKS_VERSION"
   git checkout ${APPSODY_STACKS_VERSION}
fi

# Build appsody binary from source code on Power
cd $wrkdir
cp -f ./Dockerfile-stack ./stacks/incubator/java-microprofile/image/Dockerfile-stack
cp -f ./Dockerfile ./stacks/incubator/java-microprofile/image/project/Dockerfile

cd ./stacks/incubator/java-microprofile

appsody stack validate 

echo "Appsody stack - java-microprofile is validated !"