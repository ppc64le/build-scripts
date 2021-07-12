# ----------------------------------------------------------------------------
#
# Package               : binaryextensions
# Version               : 2.2.0
# Source repo           : https://github.com/bevry/binaryextensions
# Tested on             : UBI 8.3
# Script License        : Apache License, Version 2 or later
# Passing Arguments     : Passing Arguments: 1.Version of package,
# Script License        : Apache License, Version 2 or later
# Maintainer            : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer            : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash


export REPO=https://github.com/bevry/binaryextensions

#clone from default tag v2.2.0 
if [ -z "$1" ]; then
  export VERSION="v2.2.0"
else
  export VERSION="$1"
fi

if [ -d "binaryextensions" ] ; then
  rm -rf binaryextensions
fi

#Install Dependencies
if [ ! -d ~/.nvm ]; then
    sudo yum update -y
    sudo yum groupinstall 'Development Tools' -y
    sudo yum install -y openssl-devel.ppc64le curl git
    sudo curl https://raw.githubusercontent.com/creationix/nvm/v0.37.2/install.sh | bash
fi

source ~/.bashrc
if [ `nvm list | grep -c "v12.22.3"` -eq 0 ]
then
    nvm install 12.22.3
fi

cd $HOME

#clone Repo
git clone ${REPO}

## Build and test binaryextensions
cd binaryextensions
git checkout ${VERSION}
ret=$?

if [ $ret -eq 0 ] ; then
  echo "$Version found to checkout "
else
  echo "$Version not found "
  exit
fi
node --version
npm --version

#install & test
npm install | tee binaryextensions.${VERSION}.install.log
ret=$?
if [ $ret -eq 0 ] ; then
  echo "Build successfully "
  npm audit fix --force
  npm fund
  echo "Ran fund & audit fix successfully"
  npm test 2>binaryextensions.${VERSION}.test.log | tee ./binaryextensions.${VERSION}.test.err
# grep error content from log to verify test failures
  grep -in 'error' binaryextensions.${VERSION}.test.log
  ret=$?
  if [ $ret -eq 1 ] ; then
   echo "Build & Test completed successfully."
  else
   echo "Test failed. "
  fi
else
  echo "Build failed. "
fi
