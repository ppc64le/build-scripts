#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package         : eclipse/che-plugin-registry
# Version         : 7.60.1
# Source repo     : https://github.com/eclipse/che-plugin-registry
# Tested on       : rhel 8.5
# Language        : Typescript
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Shubham Bhagwat <shubham.bhagwat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORKDIR=`pwd`
BUILD_VERSION=${1:-7.60.1}
PACKAGE_URL=https://github.com/eclipse/che-plugin-registry.git 
PACKAGE_NAME=che-plugin-registry

echo "Installing libraries and dependencies..."
yum install git wget -y
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
yum install npm -y

wget https://download.docker.com/linux/static/stable/ppc64le/docker-18.06.3-ce.tgz 
tar xzvf docker-18.06.3-ce.tgz 
cp docker/* /usr/bin/ 
wget https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.service 
wget https://raw.githubusercontent.com/moby/moby/master/contrib/init/systemd/docker.socket 
cp docker.* /etc/systemd/system/ 
groupadd docker
usermod -a -G docker <user> 
systemctl enable docker 
systemctl start docker 
systemctl status docker 

echo "configuring npm and nvm..."
npm install -g -y yarn
nvm install 14
nvm use 14

echo "Installing additional dependencies..."
yum install -y python39
export PYTHONPATH=/usr/local/bin/python3

git clone $PACKAGE_URL $PACKAGE_NAME; 
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

sed -i 's/x86_64/ppc64le/g' build/dockerfiles/Dockerfile
sed -i 's/x64/ppc64le/g' build/dockerfiles/import-vsix.sh
./build.sh -t 7.60.1-rhel
