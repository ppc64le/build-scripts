# ----------------------------------------------------------------------------
#
# Package               : go-kmsg-parser
# Version               : 2.0.1,2.1.0
# Source repo           : https://github.com/euank/go-kmsg-parser
# Tested on             : UBI 8.3
# Script License        : Apache License, Version 2 or later
# Passing Arguments     : Passing Arguments: 1.Version of package,
# Script License        : Apache License, Version 2 or later
# Maintainer            : Arumugam N S<asellappen@yahoo.com>/Priya Seth<sethp@us.ibm.com>
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
  export VERSION=v2.1.0
else
  export VERSION=$1
fi

if [ -d "go-kmsg-parser" ] ; then
  rm -rf go-kmsg-parser
fi

# Dependency installation
sudo dnf install -y git make golang
# Download the repos
git clone https://github.com/euank/go-kmsg-parser


# Build and Test go-kmsg-parser
cd go-kmsg-parser
git checkout $VERSION
ret=$?
if [ $ret -eq 0 ] ; then
 echo "$VERSION found to checkout "
else
 echo "$VERSION not found "
 exit
fi

#Build and test
make test-deps
ret=$?
if [ $ret -ne 0 ] ; then
  echo "Install dep failed "
  exit
else
  echo "Install dep success"
fi
make test
ret=$?
if [ $ret -ne 0 ] ; then
    echo "Tests failed "
else
    echo "Tests Success "
fi
make
ret=$?
if [ $ret -ne 0 ] ; then
    echo "make failed "
else
    echo "make Success "
fi
