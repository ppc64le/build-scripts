#----------------------------------------------------------------------------
#
# Package         : tuchk4/storybook-readme
# Version         : storybook-readme@5.0.5
# Source repo     : https://github.com/tuchk4/storybook-readme.git
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

REPO=https://github.com/tuchk4/storybook-readme.git

# Default tag storybook-readme
if [ -z "$1" ]; then
  export VERSION="storybook-readme@5.0.5"
else
  export VERSION="$1"
fi

yum install git wget -y
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=$CWD/node-v12.22.4-linux-ppc64le/bin:$PATH
npm install yarn -g

#Cloning Repo
git clone $REPO
cd  storybook-readme/
git checkout ${VERSION}

#Build repo
yarn install
#Test repo
#yarn test
#no test files 


         