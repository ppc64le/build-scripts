# ----------------------------------------------------------------------------
# Package       : tini
# Version       : master
# Source repo   : https://github.com/krallin/tini
# Tested on     : RHEL_7.9
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhijit Mane <abhijman@in.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------

#!/bin/bash

# clone branch passed as argument, if none, use master
if [ -z $1 ] 
then
	BRANCH=""
else
	BRANCH="--branch $1"
fi

if [ "$BRANCH" == "" ]
then
	echo "BRANCH = master"
else
	echo "BRANCH = $BRANCH"
fi

# clone, build & test
git clone $BRANCH https://github.com/krallin/tini.git || (echo "git clone failed"; exit $?)
cd tini
cmake .
make 

# tini spawns 'echo' process & waits for it's exit while reaping any zombies
./tini -sv echo "testing tini..."

# copy build artifacts
cp -pf ./tini ../tini-ppc64le
cp -pf ./tini-static ../

# cleanup
cd ..
rm -rf tini
