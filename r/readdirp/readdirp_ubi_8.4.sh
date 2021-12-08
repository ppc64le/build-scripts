# ----------------------------------------------------------------------------
#
# Package       : readdirp
# Version       : 3.6.0
# Source repo   : https://github.com/paulmillr/readdirp
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Gururaj R Katti <Gururaj.Katti@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

if [ -z "$1" ]; then
  export VERSION=master
else
  export VERSION=$1
fi

if [ -d "readdirp" ] ; then
  rm -rf readdirp
fi

# Dependency installation
sudo dnf module install nodejs:12
sudo dnf install git
sudo dnf install wget

# Download the repos
git clone https://github.com/paulmillr/readdirp


# Build and Test readdirp
cd readdirp
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

npm install
ret=$?

if [ $ret -ne 0 ] ; then
 echo "Build failed "
 exit
else
 npm run nyc -- npm run mocha
fi
