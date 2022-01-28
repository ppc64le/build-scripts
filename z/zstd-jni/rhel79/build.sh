# ----------------------------------------------------------------------------
# Package       : zstd-jni
# Version       : master
# Source repo   : https://github.com/luben/zstd-jni
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
git clone $BRANCH https://github.com/luben/zstd-jni.git || (echo "git clone failed"; exit $?)
cd zstd-jni/sbt-jni

# build/publish locally sbt-jni plugin
./sbt publishLocal

# compile/test
cd ..
./sbt compile test package

# copy build artifacts
cp -f ./target/zstd-jni-*.jar ../

# cleanup
cd ..
rm -rf zstd-jni
