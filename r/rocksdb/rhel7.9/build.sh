# ----------------------------------------------------------------------------
# Package       : rocksdb
# Version       : master
# Source repo   : https://github.com/facebook/rocksdb
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
git clone $BRANCH https://github.com/facebook/rocksdb.git || (echo "git clone failed"; exit $?)
cd rocksdb

# build rocksdb archive, shared object
make static_lib
make shared_lib

# build jar which encapsulates the shared object (.so)
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.292.b10-1.el7_9.ppc64le
make rocksdbjava

# run tests if "runtest" is passed as argument
if [ "$1" == "runtest" ] || [ "$2" == "runtest" ]
then
	## needs VM with sufficient resources, uncomment & run
	# make clean
	# make check
fi

# copy build artifacts
cp -f librocksdb.a librocksdb.so.5.18.4 java/target/librocksdbjni-linux-ppc64le.so java/target/rocksdbjni-5.18.4-linux64.jar ../

# cleanup
cd ..
rm -rf rocksdb
