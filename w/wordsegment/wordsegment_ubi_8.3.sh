# ----------------------------------------------------------------------------
#
# Package               : python-wordsegment
# Version               : 1.3.1
# Source repo           : https://github.com/grantjenks/python-wordsegment
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

if [ -d "python-wordsegment" ] ; then
  rm -rf python-wordsegment
fi

# Dependency installation
sudo dnf install python36 -y
sudo dnf install python38 -y
sudo dnf install python39 -y
pip3 install tox nose
sudo dnf install -y git 

# Download the repos
git clone https://github.com/grantjenks/python-wordsegment


# Build and Test python-wordsegment
cd python-wordsegment
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

#Build and test with differnt python environments
tox -e py36
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for python 3.6 environment"
else
  echo "Build & Test Success for python 3.6 environment"
fi

tox -e py38
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed  for python 3.8  environment"
else
  echo "Build & Test Success for python 3.8  environment"
fi


tox -e py39
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed  for python 3.9  environment"
else
  echo "Build & Test Success for python 3.9  environment"
fi

#to cover detailed test with nosetest
nosetests -v

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed  for nosetests  "
else
  echo "Build & Test Success for  nosetests "
fi

