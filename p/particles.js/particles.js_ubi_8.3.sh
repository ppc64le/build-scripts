#----------------------------------------------------------------------------
#
# Package         : VincentGarreau/particles.js
# Version         : 2.0.0
# Source repo     : https://github.com/VincentGarreau/particles.js.git
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

REPO=https://github.com/VincentGarreau/particles.js.git

# Default tag Particles.js
if [ -z "$1" ]; then
  export VERSION="2.0.0"
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
cd  particles.js
git checkout ${VERSION}

#build repo
npm install
#test repo
#npm test
#no test files found


         