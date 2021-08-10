# ----------------------------------------------------------------------------
#
# Package       : write-file-atomic
# Version       : v3.0.3
# Source repo   : https://github.com/npm/write-file-atomic
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

if [ -d "write-file-atomic" ] ; then
  rm -rf write-file-atomic
fi

# Dependency installation
sudo dnf module install -y nodejs:12
sudo dnf install -y git
sudo dnf install -y wget

# Download the repos
git clone https://github.com/npm/write-file-atomic


# Build and Test write-file-atomic
cd write-file-atomic
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
 npm test
fi
