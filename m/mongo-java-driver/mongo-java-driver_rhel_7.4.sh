# ----------------------------------------------------------------------------
#
# Package	: mongo-java-driver
# Version	: 3.6.0
# Source repo	: https://github.com/mongodb/mongo-java-driver.git
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo yum update  -y
sudo yum install -y git autoconf libtool automake build-essential \
    mono-devel gettext libtool-bin java-1.8.0-openjdk-devel.ppc64le \
    wget tar ca-certificates-java
sudo update-ca-certificates -f

#export variables
#export MONGO_REPO="http://repo.mongodb.com/apt/ubuntu" REPO_TYPE="precise/mongodb-enterprise/2.6 multiverse"
#export SOURCES_LOC="/etc/apt/sources.list.d/mongodb-enterprise.list" KEY_SERVER="hkp://keyserver.ubuntu.com:80"
#export MONGOD_PARAMS="--setParameter=enableTestCommands=1" MONGOD_OPTS="--dbpath ./data --fork --logpath mongod.log ${MONGOD_PARAMS}"
#apt-key adv --keyserver ${KEY_SERVER} --recv 7F0CEB10
#echo "deb ${MONGO_REPO} ${REPO_TYPE}" | tee ${SOURCES_LOC}

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Build and download
git clone https://github.com/mongodb/mongo-java-driver.git
cd mongo-java-driver
git checkout r3.2.0
./gradlew assemble -x javadoc
