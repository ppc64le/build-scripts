# ----------------------------------------------------------------------------
#
# Package         : keycloak_init_containers
# Branch          : master
# Tag             : 12.0.4
# Source repo     : https://github.com/keycloak/keycloak-containers.git
# Tested on       : RHEL_8.3
# Script License  : Apache License, Version 2.0
# Maintainer      : Krishna Harsha Voora <krishvoor@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------
#!/bin/bash

# Install pre-requisites
yum update -y
yum install git -y

# clone branch/release passed as argument, if none, use last stable release
if [ -z $1 ] || [ "$1" == "laststablerelease" ]
then
	RELEASE_TAG=12.0.4
else
	RELEASE_TAG=$1
fi

echo "RELEASE_TAG = $RELEASE_TAG"

cd $HOME
git clone -b $RELEASE_TAG https://github.com/keycloak/keycloak-containers.git
cd keycloak-containers/server/

# Build keycloak-init container on latest GA

docker build -t keycloak-server-ubi83 .

# Clean-Up
rm -rf $HOME/keycloak-containers
yum remove git -y
