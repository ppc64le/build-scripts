#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package	: encoding
# Version	: 0.1.12
# Source repo	: https://github.com/andris9/encoding.git 
# Tested on	: RHEL 7.6
# Script License: 
# Maintainer	: Sarvesh Tamba <sarvesh.tamba@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# Install all dependencies.
sudo yum -y update
sudo yum -y install wget

#Install nvm
if [ ! -d ~/.nvm ]; then
        #Install the required dependencies
        sudo yum install -y openssl-devel.ppc64le curl git
        curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
fi

source ~/.nvm/nvm.sh

#Install node version v4.9.1 ('encoding' works only with node 4)
if [ `nvm list | grep -c "v4.9.1"` -eq 0 ]
then
        nvm install v4.9.1
fi

nvm alias default v4.9.1

# Download source and build libiconv from source.
wget https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.16.tar.gz
tar -xvzf libiconv-1.16.tar.gz
cd libiconv-1.16
./configure --build=ppc64le
sudo make
sudo make install
cd ../

# Clone and build npm package from source.
git clone https://github.com/andris9/encoding.git
cd encoding/
git checkout v0.1.12
 
npm config set unsafe-perm true
npm install
npm test
npm config set unsafe-perm false
