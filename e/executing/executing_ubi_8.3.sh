# ----------------------------------------------------------------------------
#
# Package               : executing
# Version               : 0.6.0
# Source repo           : https://github.com/alexmojaki/executing
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

if [ -d "executing" ] ; then
  rm -rf executing
fi

# Dependency installation

sudo dnf install python36 -y
sudo dnf  install -y git  python3-devel

# Download the repos
git clone https://github.com/alexmojaki/executing


# Build and Test executing
cd executing
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

pip3 install codecov
pip3 install --upgrade coveralls asttokens pytest setuptools setuptools_scm pep517
pip3 install -e .


#Build and test with differnt python environments
python3.6 setup.py test

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for python 3.6 environment"
else
  echo "Build & Test Success for python 3.6 environment"
fi


#coverage  test

coverage run --include=executing/executing.py --append -m pytest tests/test_pytest.py

ret=$?
if [ $ret -ne 0 ] ; then
  echo "coverage Test failed for python 3.6 environment"
else
  echo "coverage Test Success for python 3.6 environment"
fi

#coverage  report

coverage report -m
