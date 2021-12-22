# ----------------------------------------------------------------------------
#
# Package       : base64url
# Version       : v3.0.1
# Source repo   : https://github.com/brianloveswords/base64url
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

if [ -d "base64url" ] ; then
  rm -rf base64url
fi

# Dependency installation
sudo dnf module install -y nodejs:12
sudo dnf install -y git
sudo dnf install -y wget

# Download the repos
git clone https://github.com/brianloveswords/base64url


# Build and Test base64url
cd base64url
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

npm install typescript
ret=$?

if [ $ret -ne 0 ] ; then
 echo "typescript install failed "
 exit
else
 npm install
 ret=$?

 if [ $ret -ne 0 ] ; then
  echo "Build failed "
  exit
 else
  npm test
 fi
fi

