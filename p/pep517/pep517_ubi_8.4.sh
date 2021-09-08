# ----------------------------------------------------------------------------
#
# Package       : pep517
# Version       : v0.11.0, v0.10.0
# Source repo   : https://github.com/pypa/pep517
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

if [ -d "pep517" ] ; then
  rm -rf pep517
fi

# Dependency installation
sudo dnf install -y python36
sudo dnf install -y git
sudo dnf install -y wget

# Download the repos
git clone https://github.com/pypa/pep517


# Build and Test pep517
cd pep517
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
