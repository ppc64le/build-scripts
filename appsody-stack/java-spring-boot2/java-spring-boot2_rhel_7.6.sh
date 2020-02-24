# ----------------------------------------------------------------------------
#
# Package	: appsody/stacks/incubator/java-microprofile
# Version	: latest (0.9.0)
# Source repo	: https://github.com/appsody/stacks/tree/master/incubator/java-microprofile
# Tested on	: rhel_7.6
# Script License: Eclipse Public License - v 2.0
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
#
# Build docker image "adoptopenjdk:8-jdk-openj9-ubi" using the docker file - Dockerfile-adoptopenjdk_8-jdk-openj9-ubi (cloned from https://github.com/AdoptOpenJDK/openjdk-docker/blob/6ef982afbdd32a0b2195c9ee0fa36328535a3c64/8/jdk/ubi/Dockerfile.openj9.releases.full)
# Build docker image "maven:3.6-jdk-8-openj9-ubi" using the docker file - Dockerfile-maven_jdk-8-openj9-ubi ( cloned from https://github.com/carlossg/docker-maven/blob/d3dd6bc261c6173c5e52e3a7a36b6a3d8d2800b4/jdk-8-openj9/Dockerfile)
#
#
# appsody binary version 0.5.8 or greater is available in path 
# ----------------------------------------------------------------------------

export APPSODY_STACKS_VERSION=""

wrkdir=`pwd`

docker build -f Dockerfile-adoptopenjdk_8-jdk-openj9-ubi -t adoptopenjdk:8-jdk-openj9-ubi .

docker build -f Dockerfile-maven_jdk-8-openj9-ubi -t maven:3.6-jdk-8-openj9-ubi .

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

cd ./incubator/java-spring-boot2
# NOTE :: Modify stacks.yaml to use  baseimage: maven:3.6-ibmjava-8-ubi

appsody stack validate 

echo "Appsody stack - java-spring-boot2 is validated !"