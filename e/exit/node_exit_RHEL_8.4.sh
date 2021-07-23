# ----------------------------------------------------------------------------
#
# Package		    : exit
# Version		    : 0.1.2
# Source repo	  : https://github.com/cowboy/node-exit.git
# Tested on		  : fedora_8.4
# Script License: Apache License, Version 2 or later
# Maintainer	  : Ram K<ramakrishna.s@genisys-group.com>/Priya Seth<sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


#!/bin/bash


export REPO=https://github.com/cowboy/node-exit.git

#Default tag 0.1.2
if [ -z "$1" ]; then
  export VERSION="v0.1.2"
else
  export VERSION="$1"
fi



#Default installation
dnf module install nodejs:12
sudo yum update
sudo yum install git -y

#For rerunning build
if [ -d "node-exit" ] ; then
  rm -rf node-exit
fi

git clone ${REPO}
cd node-exit
git checkout ${VERSION}
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "${VERSION} found to checkout"
else
  echo  "${VERSION} not found"
  exit
fi

#run the test
npm install 

npm audit fix --force

npm fund
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done build ..."
else
  echo  "Failed build......"
  exit
fi 
npm install -g grunt-cli
npm test
ret=$?
if [ $ret -eq 0 ] ; then
  echo  "Done Test ......"
else
  echo  "Failed Test ......"
fi
