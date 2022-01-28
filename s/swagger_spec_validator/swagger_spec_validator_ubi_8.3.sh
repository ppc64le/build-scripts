# ----------------------------------------------------------------------------
#
# Package               : swagger_spec_validator
# Version               : 2.7.3
# Source repo           : https://github.com/Yelp/swagger_spec_validator
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

if [ -d "swagger_spec_validator" ] ; then
  rm -rf swagger_spec_validator
fi

# Dependency installation
sudo dnf install python36 -y
sudo dnf install -y git
pip3 --version
pip3 install tox
# Download the repos
git clone https://github.com/Yelp/swagger_spec_validator


# Build and Test  swagger_spec_validator
cd swagger_spec_validator
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

#Build and test with options default,simplejson,pre-commit & cover
tox -e py36-default
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for default"
else
  echo "Build & Test Success for default"
fi

tox -e py36-simplejson
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for simplejson"
else
  echo "Build & Test Success for simplejson"
fi

tox -e pre-commit
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for pre-commit"
else
  echo "Build & Test Success for pre-commit"
fi


tox -e cover
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for cover"
else
  echo "Build & Test Success for cover"
fi
