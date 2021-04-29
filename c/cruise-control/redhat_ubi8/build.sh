# ----------------------------------------------------------------------------
#
# Package       : cruise-control
# Version       : master (default)
# Source repo   : https://github.com/linkedin/cruise-control
# Tested on     : RHEL_8
# Script License: Apache License, Version 2 or later
# Maintainer    : Amir Sanjar <amir.sanjar@ibm.com>
#
# Disclaimer: This script has been tested in a root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
if [ -z $1 ] 
then
	# Master branch
	BRANCH=""
else
	BRANCH="--branch "$1
fi
BUILD_DIR=""cruise-control
## Exit if git operation failed
git clone $BRANCH  https://github.com/linkedin/cruise-control $BUILD_DIR || exit "$?"

cd $BUILD_DIR
# Exit if build failed
./gradlew jar || exit "$?"
cp ./cruise-control-metrics-reporter/build/libs/cruise-control-metrics-reporter*.jar /ws/
cd ..
rm -rf $BUILD_DIR
