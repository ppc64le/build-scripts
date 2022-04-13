# ----------------------------------------------------------------------------------------------------
#
# Package       : dygraphs
# Version       : 2.1.0, master
# Tested on     : UBI 8.3 (Docker)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sumit Dubey <Sumit.Dubey2@ibm.com>
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------------------------------

#Halt on error and echo commands
set -ex

#Variables
NAME=dygraphs
VERSION=v2.1.0
REPO=https://github.com/danvk/$NAME

#Extract version from command line
echo "Usage: $0 [-v <VERSION>]"
echo "VERSION is an optional paramater whose default value is ${VERSION}, not all versions are supported."
VERSION="${1:-$VERSION}"

#Dependencies
yum install -y git fontconfig-devel wget bzip2 java-1.8.0-openjdk-devel
dnf module install -y nodejs:14
cd /opt
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
export PATH=$PATH:/opt/phantomjs-2.1.1-linux-ppc64/bin/

#Clone
git clone $REPO
cd $NAME
git checkout $VERSION
sed -i 's#"phantomjs": "^1.9.7-8",##g' package.json
sed -i 's#"mocha-phantomjs": "3.5.3"#"mocha-phantomjs": "4.1.0"#g' package.json

#Node dependencies
npm install
npm audit fix
cp -f /opt/phantomjs-2.1.1-linux-ppc64/bin/phantomjs /opt/dygraphs/node_modules/phantomjs/lib/phantom/bin/phantomjs

#Build
npm run build
npm run build-tests

#Test
if ! npm run test; then
	set +ex
	echo "------------------Build Success but test fails---------------------"
else
	set +ex
	echo "------------------Build and test success-------------------------"
fi
# The leaks, if any, are inside the informal pp64cle phantomjs executable and have nothing to do with dygraphs
