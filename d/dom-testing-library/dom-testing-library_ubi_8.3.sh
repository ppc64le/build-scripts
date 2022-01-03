#----------------------------------------------------------------------------
#
# Package         : testing-library/dom-testing-library
# Version         : v6.10.0
# Source repo     : https://github.com/testing-library/dom-testing-library.git
# Tested on       : ubi:8.3
# Script License  : MIT License
# Maintainer      : srividya chittiboina <Srividya.Chittiboina@ibm.com>
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
# ----------------------------------------------------------------------------

REPO=https://github.com/testing-library/dom-testing-library.git

# Default tag dom-testing-library
if [ -z "$1" ]; then
  export VERSION="v6.10.0"
else
  export VERSION="$1"
fi

yum install git wget -y

#Install nodejs:12
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=$CWD/node-v12.22.4-linux-ppc64le/bin:$PATH


#Cloning Repo
git clone $REPO
cd  dom-testing-library
git checkout ${VERSION}
npm install yarn -g

#Build repo
yarn install
#Test repo
yarn test a


         