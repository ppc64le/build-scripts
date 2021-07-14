# ----------------------------------------------------------------------------
#
# Package               : watchpack
# Version               : 1.7.5
# Source repo           : https://github.com/webpack/watchpack
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


export REPO=https://github.com/webpack/watchpack

#clone from default tag v1.7.5
if [ -z "$1" ]; then
  export VERSION="v1.7.5"
else
  export VERSION="$1"
fi

if [ -d "watchpack" ] ; then
  rm -rf watchpack
fi

#Install Dependencies
if [ ! -d ~/.nvm ]; then
    yum install sudo -y
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

npm install --global yarn

#clone Repo
git clone ${REPO}

## Build and test watchpack
cd watchpack
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
yarn --version


#install & test
npm install | tee watchpack.${VERSION}.install.log
ret=$?
if [ $ret -eq 0 ] ; then
  echo "Build successfully "
  npm audit fix --force
  npm fund
  echo "Ran fund & audit fix successfully"
  npm test 2>watchpack.${VERSION}.test.log | tee ./watchpack.${VERSION}.test.err
# grep error content from log to verify test failures
  grep -in 'error' watchpack.${VERSION}.test.log
  ret=$?
  if [ $ret -eq 1 ] ; then
   echo "Build & Test completed successfully."
  else
   echo "Test failed. "
  fi
else
  echo "Build failed. "
fi
