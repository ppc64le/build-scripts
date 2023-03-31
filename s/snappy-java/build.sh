#!/bin/bash
# ----------------------------------------------------------------------------
# Package       : snappy-java
# Version       : master
# Source repo   : https://github.com/xerial/snappy-java
# Tested on     : RHEL_7.9
# Language      : Java, C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Krishna Harsha Voora <krishvoor@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------


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

git clone $BRANCH https://github.com/xerial/snappy-java || (echo "git clone failed"; exit $?)
cd snappy-java

# Update PATH Variable

export PATH=${PATH}:/usr/local/bin/apache-maven-3.6.3/bin/

# Trigger the build
make

# copy build artifacts
cp -f ./target/snappy-java*.jar ../

# cleanup
cd ..
rm -rf snappy-java
