# ----------------------------------------------------------------------------
#
# Package       : importlib_resources
# Version       : v5.2.2, v5.2.1, v5.1.2
# Source repo   : https://github.com/python/importlib_resources
# Tested on     : UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Nageswara Rao K<nagesh4193@gmail.com>/Priya Seth<sethp@us.ibm.com>
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
  export VERSION=main
else
  export VERSION=$1
fi

if [ -d "importlib_resources" ] ; then
  rm -rf importlib_resources
fi

# Dependency installation
sudo dnf install python36 -y
sudo dnf install -y git gcc python3-devel
pip3 --version
pip3 install tox
# Download the repos
git clone https://github.com/python/importlib_resources


# Build and Test  importlib_resources
cd importlib_resources
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

#Build and test with different python environments
tox -e py36

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for python 3.6 environment"
else
  echo "Build & Test Success for python 3.6 environment"
fi
