# ----------------------------------------------------------------------------------------------------
#
# Package       : jquery
# Version       : 3.6.0
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
# Instructions	: 1. Run the docker conatiner as: 
#		  docker run -t -d --privileged registry.access.redhat.com/ubi8/ubi:8.3 /usr/sbin/init
#		  2. Connect to the docker container
#		  docker exec -it <container id> bash
#		  3. Run this script
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

#!/bin/bash

set -ex

#Variables
REPO=https://github.com/jquery/jquery.git
PACKAGE_VERSION=3.6.0

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is 3.6.0, not all versions are supported."

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum install git sed unzip -y

dnf module install -y nodejs:14

#clone the repo
cd /opt && git clone $REPO
cd jquery/
git checkout $PACKAGE_VERSION

#build
npm install
npm audit fix
npm run build

#conclude
echo "Build Complete. Uncomment the following lines to run tests, they may take a while to complete."


#dnf -y install \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm \
#http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
#dnf install -y httpd firewalld
#systemctl enable httpd
#systemctl start httpd
#dnf install firewalld
#systemctl enable firewalld
#systemctl start firewalld
#firewall-cmd --zone=public --permanent --add-service=http
#firewall-cmd --reload
#sed -i 's#DocumentRoot /var/www/html#"DocumentRoot /"#g' /etc/httpd/conf/httpd.conf
#httpd -k restart
#dnf remove -y module nodejs
#dnf module reset nodejs
#yum install -y python3 libarchive
#yum install -y firefox
#cd /opt
#git clone https://github.com/ppc64le/build-scripts.git
#cd build-scripts/c/chromium
#sed -i "s#./chromedriver --version#echo \$(pwd) > /opt/chrome.binary#g" Chromium_84.0.4118.0_UBI.sh
#./Chromium_84.0.4118.0_UBI.sh
#CHROME_DIR=$(cat /opt/chrome.binary)
#export CHROME_BIN=$CHROME_DIR/chrome
#chmod 777 $CHROME_BIN
#dnf module install -y nodejs:12
#cd /opt/jquery
#sed -i "s#this.browserDisconnectTimeout = 2000#this.browserDisconnectTimeout = 210000#g" /opt/jquery/node_modules/karma/lib/config.js
#sed -i "s#this.captureTimeout = 60000#this.captureTimeout = 210000#g" /opt/jquery/node_modules/karma/lib/config.js
#sed -i "s#this.browserNoActivityTimeout = 30000#this.browserNoActivityTimeout = 210000#g" /opt/jquery/node_modules/karma/lib/config.js
#sed -i "s#this.browserDisconnectTolerance = 0#this.browserDisconnectTolerance = 3#g" /opt/jquery/node_modules/karma/lib/config.js
#sed -i "s#'--headless'#'--headless', '--no-sandbox'#g" /opt/jquery/node_modules/karma-chrome-launcher/index.js
#npm test
#echo "Tests Complete!"
