# ----------------------------------------------------------------------------
#
# Package	: mongo-java-driver
# Version	: 3.6.0
# Source repo	: https://github.com/mongodb/mongo-java-driver.git
# Tested on	: ubuntu_16.04
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

sudo apt-get update -y
sudo apt-get install -y git autoconf libtool automake build-essential mono-devel gettext \
    libtool-bin dirmngr wget tar ca-certificates-java
sudo update-ca-certificates -f

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=$PATH:$JAVA_HOME/bin

#export variables
export MONGO_REPO="http://repo.mongodb.com/apt/ubuntu" REPO_TYPE="precise/mongodb-enterprise/2.6 multiverse"
export SOURCES_LOC="/etc/apt/sources.list.d/mongodb-enterprise.list" KEY_SERVER="hkp://keyserver.ubuntu.com:80"
export MONGOD_PARAMS="--setParameter=enableTestCommands=1" MONGOD_OPTS="--dbpath ./data --fork --logpath mongod.log ${MONGOD_PARAMS}"
apt-key adv --keyserver ${KEY_SERVER} --recv 7F0CEB10
echo "deb ${MONGO_REPO} ${REPO_TYPE}" | sudo tee ${SOURCES_LOC}

# Build and download
git clone https://github.com/mongodb/mongo-java-driver.git
cd mongo-java-driver
git checkout r3.2.0
# javadoc has issues, hence we do not generate docs.
./gradlew assemble -x javadoc
