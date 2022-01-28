# ----------------------------------------------------------------------------
#
# Package       : protoc 
# Version       : 3.5.1-1
# Source repo   : https://github.com/protocolbuffers/protobuf.git
# Tested on     : ubuntu 20.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Amir Sanjar <amir.sanjar@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -ex
if [ -z $1 ] 
then
	# Master branch
	BRANCH="master"
else
	BRANCH=$1
fi
BUILD_DIR="protoc."$BRANCH
## Exit if git operation failed
git clone --branch $BRANCH https://github.com/protocolbuffers/protobuf.git $BUILD_DIR || exit "$?"

cd $BUILD_DIR
## Apply ppc64le patch
git apply ../protoc-3.5.1.patch
./autogen.sh
./configure --prefix=/usr
make && make check
make install
cd protoc-artifacts
# Exit if build or test failed
mvn clean package -DskipTests || exit "$?"
mv protoc-artifacts ../
echo "To copy to your maven local repo, execute:
cp protoc-artifacts/target/protoc.exe to ~/.m2/repository/com/google/protobuf/protoc/3.5.1-1/protoc-3.5.1-1-linux-ppcle_64.exe
or 
cd protoc-artifacts; mvn install"
cd ..
rm -rf $BUILD_DIR

