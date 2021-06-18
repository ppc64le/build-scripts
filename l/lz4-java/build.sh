# ----------------------------------------------------------------------------
# Package       : lz4-java
# Version       : master
# Source repo   : https://github.com/lz4/lz4-java
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

# clone
git clone $BRANCH https://github.com/lz4/lz4-java.git || (echo "git clone failed"; exit $?)
cd lz4-java
git submodule init
git submodule update
ant ivy-bootstrap
ant 

# copy build artifacts
cp -f ./dist/lz4-java-*-SNAPSHOT.jar ../

# cleanup
cd ..
rm -rf lz4-java
