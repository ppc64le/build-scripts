# ----------------------------------------------------------------------------
#
# Package               : chalice
# Version               : 1.24.2,1.22.4 ,1.21.8
# Source repo           : https://github.com/aws/chalice
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

if [ -d "chalice" ] ; then
  rm -rf chalice
fi

# Dependency installation
sudo dnf install python36 -y
sudo dnf install -y git make  python36-devel openssl-devel.ppc64le gcc
sudo dnf install  nodejs npm  -y

# Download the repos
git clone https://github.com/aws/chalice


# Build and Test chalice
cd chalice
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

#PRCheck
pip3 install pytest
pip3 install -r requirements-dev.txt -r requirements-docs.txt
pip3 install -e .
#At file test_package.py, env variable is setup only for x86_64-linux to make sure that the commonly used python packages can be packaged successfully ,missing setup for ppc64le,hence failing,so ignoring this particular test file from path tests/integration
mv  tests/integration/test_package.py tests/integration/ignore_test_package.py
make prcheck
ret=$?
if [ $ret -ne 0 ] ; then
  echo "make failed for python 3.6 environment"
else
  echo "make Success for python 3.6 environment"
fi

#CDK test
#tests/functional/cdk folder not available for  "1.21.8" ,so skipping
if  [ $VERSION != "1.21.8" ] ; then
  npm install -g aws-cdk
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "npm aws-cdk install failed "
  else
    echo "npm aws-cdk  Success "
  fi

  pip3 install -e .[cdk]
  python3.6 -m pytest tests/functional/cdk
  ret=$?
  if [ $ret -ne 0 ] ; then
    echo "cdktests Test failed "
  else
    echo "cdktests Test Success "
  fi
fi
