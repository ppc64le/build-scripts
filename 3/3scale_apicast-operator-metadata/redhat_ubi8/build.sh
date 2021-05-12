# ----------------------------------------------------------------------------
# Package       : apicast-operator-metadata
# Version       : v0.3.1
# Source repo   : https://github.com/3scale/apicast-operator-metadata
# Tested on     : RHEL_8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhijit Mane <abhijman@in.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------


#!/bin/bash

# clone branch/release passed as argument, if none, use last release: v0.3.1
if [ -z $1 ] || [ "$1" == "lasttestedrelease" ]
then
	# As of 30-Apr-2021, this was tagged as 'latest_release'
	BRANCH="--branch v0.3.1"
else
	BRANCH="--branch $1"
fi

echo "BRANCH = $BRANCH"

(git clone $BRANCH https://github.com/3scale/apicast-operator-metadata) || (echo "git clone failed"; exit $?)
cd apicast-operator-metadata

# build
make verify-manifest

# copy artifacts
cp -rf .bundle ../

# cleanup
cd ..
rm -rf apicast-operator-metadata
