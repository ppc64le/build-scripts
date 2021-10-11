# ----------------------------------------------------------------------------
#
# Package               : openapi-schema-validator
# Version               : 0.1.4 & 0.1.5
# Source repo           : https://github.com/p1c2u/openapi-schema-validator
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

if [ -d "openapi-schema-validator" ] ; then
  rm -rf openapi-schema-validator
fi

# Dependency installation

sudo dnf install python36 -y
sudo dnf  install -y git  python3-devel
pip3 install codecov

# Download the repos
git clone https://github.com/p1c2u/openapi-schema-validator


# Build and Test  openapi-schema-validator
cd openapi-schema-validator
git checkout $VERSION

ret=$?

if [ $ret -eq 0 ] ; then
 echo "$Version found to checkout "
else
 echo "$Version not found "
 exit
fi

#Build and test
pip3 install -r requirements.txt
pip3 install -r requirements_dev.txt
pip3 install -e .

python3.6 setup.py test

ret=$?
if [ $ret -ne 0 ] ; then
  echo "Build & Test failed for python 3.6 environment"
else
  echo "Build & Test Success for python 3.6 environment"
fi
