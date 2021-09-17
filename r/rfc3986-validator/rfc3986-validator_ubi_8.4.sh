# ----------------------------------------------------------------------------
#
# Package       : rfc3986-validator
# Version       : v0.1.0
# Source repo   : https://github.com/naimetti/rfc3986-validator
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

if [ -d "rfc3986-validator" ] ; then
  rm -rf rfc3986-validator
fi

# Dependency installation
sudo dnf install -y python36
sudo dnf install -y git
sudo dnf install -y wget

# Download the repos
git clone https://github.com/naimetti/rfc3986-validator


# Build and Test rfc3986-validator
cd rfc3986-validator
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

sudo pip3 install tox

ret=$?

if [ $ret -ne 0 ] ; then
 echo "dependency python pkg install failed "
 exit
else
  tox -e py36
fi
