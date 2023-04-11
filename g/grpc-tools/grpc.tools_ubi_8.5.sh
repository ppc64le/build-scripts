#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: GRPC
# Version	: v1.50.0
# Source repo	: https://github.com/grpc/grpc
# Tested on	: UBI 8.5
# Language      : CSharp
# Travis-Check  : True
# Script License: Apache License, Version 2
# Maintainer	: Amit Sirohi {Amit.Sirohi@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=grpc
PACKAGE_VERSION=${1:-v1.50.0}
PACKAGE_URL=https://github.com/grpc/grpc

yum update -y
#Install dependencies
yum install -y git wget curl gcc clang zip

#Install dotnet
yum install -y dotnet-sdk-7.0

#Install bazel 
yum copr enable -y vbatts/bazel
yum install -y bazel5

#clone the repository
git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule init
git submodule update
cd third_party
git submodule add https://github.com/bufbuild/protoc-gen-validate.git
cd ..

#apply patch for grpc

if ! git apply ../grpc_v1.50.0.patch; then 
	echo "$PACKAGE_NAME $PACKAGE_VERSION patch apply fails"
	exit 0
fi

#delete existing bazel in repo 
rm -f tools/bazel
 
#run bazel command from grpc repo
bazel build @com_google_protobuf//:protoc //src/compiler:all

#For Build goto the grpc/src/csharp directory
cd src/csharp/
if ! dotnet build --configuration Release Grpc.sln; then 
	echo "$PACKAGE_NAME $PACKAGE_VERSION build Grpc.sln fails"
	exit 0
fi

## To Create Grpc.Tools nuget package to use it locally

if ! ./build_nuget.sh; then
	 echo "$PACKAGE_NAME $PACKAGE_VERSION Create Grpc.Tools nuget package failed"
	exit 0
fi 

echo "Testing $PACKAGE_NAME with $PACKAGE_VERSION"
cd Grpc.Tools.Tests
dotnet run --framework net7.0
