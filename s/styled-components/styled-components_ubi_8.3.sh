#----------------------------------------------------------------------------
#
# Package         : styled-components/styled-components
# Version         : v5.3.3
# Source repo     : https://github.com/styled-components/styled-components.git
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
#
# ----------------------------------------------------------------------------

REPO=https://github.com/styled-components/styled-components.git

# Default tag styled-components
if [ -z "$1" ]; then
  export VERSION="v5.3.3"
else
  export VERSION="$1"
fi

yum update -y
yum install gcc gcc-c++ cmake git make python2 wget -y
ln -s /usr/bin/python2  /usr/bin/python

#install nodejs:12
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz" &&
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz &&
export PATH=$CWD/node-v12.22.4-linux-ppc64le/bin:$PATH
npm install yarn -g
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=skipdownload

#Cloning Repo
git clone $REPO
cd styled-components
git checkout ${VERSION}

#Build repo
yarn install
#Test repo
yarn test