#----------------------------------------------------------------------------
#
# Package         : json-schema-faker
# Version         : v0.5.0-rcv.40
# Source repo     : https://github.com/json-schema-faker/json-schema-faker
# Tested on       : ubi:8.3
# Language        : Javascript
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
#
#
# ----------------------------------------------------------------------------

set -e

WORK_DIR=`pwd`

PACKAGE_NAME=json-schema-faker
PACKAGE_VERSION=${1:-v0.5.0-rcv.40}                
PACKAGE_URL=https://github.com/json-schema-faker/json-schema-faker

# install dependencies
yum install git wget bzip2 fontconfig-devel make gcc gcc-c++ jq -y

# install phantomjs
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -s /phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/phantomjs-2.1.1-linux-ppc64/bin/phantomjs

# install nodejs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
source ~/.bashrc
nvm install v12.22.4

# clone package
cd $WORK_DIR
git clone $PACKAGE_URL

cd $PACKAGE_NAME

git checkout $PACKAGE_VERSION

# to build
make build

# to execute tests
make ci