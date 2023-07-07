# --------------------------------------------------------------------------------
# Package       : opentelemetry-cpp
# Version       : v1.1.1
# Source repo   : https://github.com/open-telemetry/opentelemetry-cpp
# Tested on     : RHEL 8.5
# Script License: Apache License, Version 2 or later
# Maintainer    : Krishna H Voora <krishvoor@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given platform using
#             the mentioned version of the package. It may not work as expected 
#             with newer versions of the package and/or distribution.
#             In such case, please contact "Maintainer" of this script.
# --------------------------------------------------------------------------------

#!/bin/bash

# clone branch/release passed as argument, if none, use last stable release
if [ -z $1 ] || [ "$1" == "laststablerelease" ]
then
	RELEASE_TAG=v1.1.1
else
	RELEASE_TAG=$1
fi

echo "RELEASE_TAG = $RELEASE_TAG"

# Clone Repository
cd ~
mkdir source && cd source
git clone --recursive -b $RELEASE_TAG https://github.com/open-telemetry/opentelemetry-cpp
cd opentelemetry-cpp

# Build Opentelemetry
mkdir build && cd build
cmake ..
cmake --build . --target all

# Install opentelemetry
mkdir -p /opt/opentelemetry-cpp/
cmake --install . --config Debug --prefix /opt/opentelemetry-cpp/

# run tests if "runtest" is passed as argument
if [ "$2" == "runtest" ]
then
	# Unit-tests
	ctest
fi

# copy binaries
cp -R /opt/opentelemetry-cpp/ ../

# cleanup
cd ..
rm -rf opentelemetry-cpp/
