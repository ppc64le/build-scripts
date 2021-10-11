#----------------------------------------------------------------------------
#
# Package         : jslicense/spdx-exceptions.json
# Version         : v2.3.0
# Source repo     : https://github.com/jslicense/spdx-exceptions.json.git
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
# !/bin/bash
# Tested Versions: v2.1.0, v2.2.0, v2.3.0
# ----------------------------------------------------------------------------

REPO=https://github.com/jslicense/spdx-exceptions.json.git

# Default tag Spdx-exceptions.json
if [ -z "$1" ]; then
  export VERSION="v2.3.0"
else
  export VERSION="$1"
fi

dnf install git wget -y
#Install Nodejs version 12 or above 
wget "https://nodejs.org/dist/v12.22.4/node-v12.22.4-linux-ppc64le.tar.gz"
tar -xzf node-v12.22.4-linux-ppc64le.tar.gz
export PATH=$CWD/node-v12.22.4-linux-ppc64le/bin:$PATH

#Cloning Repo
git clone $REPO
cd spdx-exceptions.json
git checkout ${VERSION}

#build repo
npm install
#test repo
#npm test
#no test files found


         