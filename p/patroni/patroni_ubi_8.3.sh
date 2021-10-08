# ----------------------------------------------------------------------------
#
# Package               : patroni
# Version               : 2.1.1
# Source repo           : https://github.com/zalando/patroni
# Tested on             : UBI 8.3
# Script License        : Apache License, Version 2 or later
# Passing Arguments     : Passing Arguments: 1.Version of package,
# Note                  : working only for py39 & py38 ,test failing in py36
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

if [ -d "patroni" ] ; then
  rm -rf patroni
fi

# Dependency installation

sudo dnf install python38 -y
sudo dnf  install -y git  python38-devel
sudo dnf install rust cargo -y


# Download the repos
git clone https://github.com/zalando/patroni


# Build and Test patroni
cd patroni
git checkout $VERSION

ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION  not found "
 exit
fi


#Build and test with differnt python environments
pip3 install Cython
pip3 install -r requirements.txt
pip3 install -e .

#Install dependencies
python3.8 .github/workflows/install_deps.py
#Run tests and flake8
python3.8 .github/workflows/run_tests.py

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed  for python 3.8 environment"
else
  echo "Build & Test success for python 3.8 environment"
fi
