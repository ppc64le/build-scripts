# ----------------------------------------------------------------------------
#
# Package       : oclif/config
# Version       : v1.17.0
# Source repo   : https://github.com/oclif/config
# Tested on     : ubi: 8.3
# Script License: Apache License 2.0
# Maintainer's  : Hari Pithani <Hari.Pithani@ibm.com>
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

REPO=https://github.com/oclif/config.git

# Installation of prerequisites.
yum update -y
yum install git nodejs-devel.ppc64le -y
yum install java-11-openjdk-devel -y
rpm --import https://dl.yarnpkg.com/rpm/pubkey.gpg 
curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo 
dnf install yarn --disablerepo=AppStream -y

#Default tag config
if [ -z "$1" ]; then
  export VERSION="v1.17.0"
else
  export VERSION="$1"
fi

#For rerunning build
if [ -d "config" ] ; then
  rm -rf config
fi

git clone ${REPO}
cd config
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi

npm install
yarn install
yarn test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi