#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : grunt-spritesmith
# Version       : 6.4.0
# Source repo   : https://github.com/twolfson/grunt-spritesmith.git
# Tested on     : RHEL 7.6
# Node Version  : v8.9.4
# Maintainer    : Amol Patil <amol.patil2@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

set -e

# Install all dependencies.
sudo yum clean all
sudo yum -y update
sudo yum install -y java-1.8.0-openjdk

#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y openssl-devel.ppc64le curl git
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v8.9.4
if [ `nvm list | grep -c "v8.9.4"` -eq 0 ]
then
        nvm install v8.9.4
fi

nvm alias default v8.9.4

#clone and build npm package from source
git clone https://github.com/aheckmann/gm.git && cd gm
git checkout v0.5.0
npm install 
cd ..

git clone https://github.com/twolfson/gmsmith.git && cd gmsmith
git checkout 1.2.0
sed -i "26d" ./package.json
sed -i "31d" ./package.json

npm install ../gm --save-dev
cd ..


git clone https://github.com/twolfson/grunt-spritesmith.git && cd grunt-spritesmith
git checkout 6.4.0

npm install ../gmsmith
npm install .
#npm test

npm config set unsafe-perm true

