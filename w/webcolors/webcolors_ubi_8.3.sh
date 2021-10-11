# ----------------------------------------------------------------------------
#
# Package               : webcolors
# Version               : 1.11.1
# Source repo           : https://github.com/ubernostrum/webcolors
# Tested on             : UBI 8.3
# Script License        : Apache License, Version 2 or later
# Passing Arguments     : Passing Arguments: 1.Version of package,
# Script License        : Apache License, Version 2 or later
# Maintainer            : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer            : This script has been tested in non-root mode on given
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

if [ -d "webcolors" ] ; then
  rm -rf webcolors
fi

# Dependency installation
sudo dnf install python36 -y
sudo dnf install python38 -y
sudo dnf install python39 -y
sudo dnf install -y git gcc
pip3 install tox

# Download the repos
git clone https://github.com/ubernostrum/webcolors


# Build and Test webcolors
cd webcolors
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

#Build and test with differnt python enviroments
tox -e py36
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for python 3.6 enviroment"
else
  echo "Build & Test Success for python 3.6 enviroment"
fi

tox -e py38
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed  for python 3.8  enviroment"
else
  echo "Build & Test Success for python 3.8  enviroment"
fi

tox -e py39
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed  for python 3.9  enviroment"
else
  echo "Build & Test Success for python 3.9  enviroment"
fi

tox -e  flake8

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed  for flake8  enviroment"
else
  echo "Build & Test Success for flake8  enviroment"
fi
tox -e  isort

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed  for isort  enviroment"
else
  echo "Build & Test Success for isort  enviroment"
fi

tox -e docs

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed  for docs  enviroment"
else
  echo "Build & Test Success for  docs  enviroment"
fi

