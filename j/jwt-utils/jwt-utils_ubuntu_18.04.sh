# ----------------------------------------------------------------------------
#
# Package        : jwt-utils
# Version        : 0.1.0
# Source repo    : https://github.com/Around25/jwt-utils
# Tested on      : ubuntu_18.04
# Script License : Apache License, Version 2 or later
# Maintainer     : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer     : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export REPO=https://github.com/Around25/jwt-utils

#no tag present so directly clone from master
if [ -z "$1" ]; then
  export VERSION="origin/master"
else
  export VERSION="$1"
fi



sudo apt-get update
sudo apt-get install  nodejs npm git curl -y

if [ -d "jwt-utils" ] ; then
  rm -rf jwt-utils
fi


git clone ${REPO}


## Build and test jwt-utils
cd jwt-utils
git checkout ${VERSION}
ret=$?

if [ $ret -eq 0 ] ; then
  echo "$Version found to checkout "
else
  echo "$Version not found "
  exit
fi

curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.35.3/install.sh -o install_nvm.sh
bash install_nvm.sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
#jest req for this package and it work from above 12.18.3
nvm install 12.18.3
npm install jest
npm install
npm run test
