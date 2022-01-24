# ----------------------------------------------------------------------------
#
# Package       : strict-rfc3339
# Version       : cordova-plugin-file-opener2, Fileopener2.java
# Tested on     : UBI 8.3 (Docker)
# Script License: GPL v3
# Maintainer    : Varsha Aaynure <Varsha.Aaynure@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -ex

#Variables
REPO=https://github.com/pwlin/cordova-plugin-file-opener2.git
PACKAGE_VERSION=3.0.5

#Install required files
yum update -y
yum install -y git wget

##Install Node 12
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=$CWD/node-v12.22.4-linux-ppc64le/bin:$PATH

#Cloning Repo
git clone $REPO
cd cordova-plugin-file-opener2/
git checkout $PACKAGE_VERSION

#Install node deps
npm install

#Build package
npm build

#Test pacakge
npm test
