# ----------------------------------------------------------------------------
#
# Package       : Bootstrap-datetimepicker
# Version       : v1.9.0
# Source repo   : https://github.com/uxsolutions/bootstrap-datepicker
# Tested on     : UBI: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Balavva Mirji <Balavva.Mirji@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Variables
REPO=https://github.com/uxsolutions/bootstrap-datepicker

# Default tag for Bootstrap-datetimepicker
if [ -z "$1" ]; then
  export VERSION="v1.9.0"
else
  export VERSION="$1"
fi

# install tools and dependent packages
yum update -y
yum install git wget bzip2 fontconfig-devel python2 make -y
ln -s /usr/bin/python3 /usr/bin/python

# install node
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=$CWD/node-v12.22.4-linux-ppc64le/bin:$PATH

# install phantomjs
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -s /phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/phantomjs-2.1.1-linux-ppc64/bin/phantomjs
git clone https://github.com/uxsolutions/bootstrap-datepicker

#Cloning Repo
git clone $REPO
cd bootstrap-datepicker
git checkout ${VERSION}

#Build and test package
npm install -g yarn
yarn --frozen-lockfile
npm install -g grunt-cli
yarn test