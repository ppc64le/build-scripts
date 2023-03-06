#!/bin/bash
#---------------------------------------------------------------------------------------------------
#
# Package       : Cypress-docker-images
# Version       : v12.5.1
# Source repo   : https://github.com/cypress-io/cypress-docker-images
# Tested on     : Ubuntu 22.04
# Language      : C++
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#---------------------------------------------------------------------------------------------------

set -eux

#Variables
NAME=cypress-docker-images
REPO=https://github.com/cypress-io/${NAME}.git
VERSION=a16d78aea46bae9919b1c0811ff7607488661463
CWD=`pwd`

if [[ ! -f cypress.zip ]]; then
	echo "Error: This script expects the Cypress distribution (cypress.zip) in the current directory ($CWD)."
	exit 1;
fi

#install ubuntu dependencies
apt-get update -y
apt-get install vim git wget -y 

#Install docker
apt-get install ca-certificates curl gnupg lsb-release -y
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
mkdir -p /etc/docker
touch /etc/docker/daemon.json
cat <<EOT > /etc/docker/daemon.json
{
"storage-driver": "overlay2"
}
EOT
service docker start
docker run hello-world

#clone
cd $CWD
git clone $REPO
cd $NAME/
git checkout $VERSION
cp $CWD/cypress.zip factory/installScripts/cypress/

#patch edge script
sed -i "16i if (process.arch === 'ppc64') {" factory/installScripts/edge/install-edge-version.js
sed -i "17i console.log('Not downloading Edge since we are on ppc64')" factory/installScripts/edge/install-edge-version.js
sed -i "18i return;" factory/installScripts/edge/install-edge-version.js
sed -i "19i }" factory/installScripts/edge/install-edge-version.js

#patch firefox script
sed -i '10,13d' factory/installScripts/firefox/default.sh
sed -i '3d' factory/installScripts/firefox/default.sh
if [ ! -f "/etc/apt/sources.list.d/sources-debian-sid.list" ]; 
then
	sed -i '3i echo "deb [trusted=yes] http://deb.debian.org/debian sid main" > /etc/apt/sources.list.d/sources-debian-sid.list' factory/installScripts/firefox/default.sh
fi
sed -i -e '$a    firefox' factory/installScripts/firefox/default.sh


#patch chrome script
if [ ! -f "/etc/apt/sources.list.d/sources-debian-sid.list" ];
then
	sed -i '11i echo "deb [trusted=yes] http://deb.debian.org/debian sid main" > /etc/apt/sources.list.d/sources-debian-sid.list' factory/installScripts/chrome/default.sh
fi
sed -i "s#apt-get install -f -y /usr/src/google-chrome-stable_current_amd64.deb#apt-get install -y chromium\nln -fs /usr/bin/chromium /usr/bin/google-chrome-stable#g" factory/installScripts/chrome/default.sh
sed -i '17d' factory/installScripts/chrome/default.sh
sed -i '3,10d' factory/installScripts/chrome/default.sh

#patch cypress script
sed -i -e '$aapt-get update -y && apt-get install -y unzip' factory/installScripts/cypress/default.sh
sed -i -e '$arm -rf /root/.cache/Cypress/${1}/Cypress' factory/installScripts/cypress/default.sh
sed -i -e '$aunzip -q /opt/installScripts/cypress/cypress.zip -d /root/.cache/Cypress/${1}/' factory/installScripts/cypress/default.sh

#patch chrome and firefox versions
sed -i "s#FIREFOX_VERSION='109.0'#FIREFOX_VERSION='108.0.2'#g" factory/.env
sed -i "s#CHROME_VERSION='109.0.5414.74-1'#CHROME_VERSION='110.0.5481.77'#g" factory/.env
sed -i "s#debian:bullseye-slim#ubuntu:22.04#g" factory/.env

#patch tests
sed -i 's#RUN ./node_modules/.bin/cypress verify#\#RUN ./node_modules/.bin/cypress verify#g' factory/test-project/Dockerfile factory/test-project/argsDefined.Dockerfile

#build
cd factory
set -a && . ./.env && set +a
docker compose build --progress plain factory
docker compose build --progress plain

#test
cd test-project
docker compose build --progress plain

#Smoke tests
docker run -it --rm cypress/cypress cypress verify
docker run -it --rm cypress/base node --version
docker run -it --rm cypress/firefox firefox --version
docker run -it --rm cypress/chrome google-chrome-stable --version

#list cypress images just built
docker images | grep cypress

#conclude
set +ex
echo "Build and test completed successfully!"
