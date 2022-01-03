# ----------------------------------------------------------------------------
# Package       : apisonator
# Version       : 3scale-2.11-stable
# Source repo   : https://github.com/3scale/apisonator
# Tested on     : RHEL_8.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Krishna Harsha Voora <krishvoor@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# ----------------------------------------------------------------------------


#!/bin/bash

# clone branch/release passed as argument, if none, use last release: v0.3.1
if [ -z $1 ] || [ "$1" == "lasttestedrelease" ]
then
	# As of 29-Oct-2021, this was tagged as 'latest_release'
	BRANCH="--branch 3scale-2.11-stable"
else
	BRANCH="--branch $1"
fi

echo "BRANCH = $BRANCH"

(git clone $BRANCH https://github.com/3scale/apisonator) || (echo "git clone failed"; exit $?)
cd apisonator

# build
make ci-build

# run tests
make DOCKER_OPTS="-e TEST_ALL_RUBIES=1" test


# cleanup
cd ..
rm -rf apisonator
