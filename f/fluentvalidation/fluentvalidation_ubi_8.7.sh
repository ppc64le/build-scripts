#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : FluentValidation
# Version       : 11.5.2
# Source repo   : https://github.com/FluentValidation/FluentValidation.git
# Tested on     : UBI 8.7
# Language      : C#
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sapana Khemkar <Sapana.Khemkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=FluentValidation
PACKAGE_VERSION=${1:-11.5.2}
PACKAGE_URL=https://github.com/FluentValidation/FluentValidation.git

DOTNET_VERSION=7.0

yum -y update && yum install -y  "dotnet-sdk-$DOTNET_VERSION" git

SDK_VERSION=$(dotnet --version)
echo ".NET SDK Version is " $SDK_VERSION

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

for file in `find . -type f -name "*.csproj"`;
do
	# update target framework
        sed -i '/^[[:blank:]]*<TargetFrameworks>/c\<TargetFrameworks>net'"$DOTNET_VERSION"'</TargetFrameworks>' $file  ;
	# update Microsoft.NET.Test.Sdk  version to higher than 17.5.0 
	sed -i '/^[[:blank:]]*<PackageReference Include=\"Microsoft.NET.Test.Sdk\"/c\<PackageReference Include=\"Microsoft.NET.Test.Sdk\" Version=\"17.6.0\" />' $file  
	sed -i '/^[[:blank:]]*<PackageReference Include=\"Microsoft.TestPlatform.TestHost\"/c\<PackageReference Include=\"Microsoft.TestPlatform.TestHost\" Version=\"17.6.0\" />' $file 
	# update version which compatable with Microsoft.NET.Test.Sdk version 17.6.0 
	sed -i '/^[[:blank:]]*<PackageReference Include=\"Newtonsoft.Json\"/c\<PackageReference Include=\"Newtonsoft.Json\" Version=\"13.0.3\" />' $file  ; 
done

cd src/FluentValidation.Tests

if ! dotnet test; then
        echo "Test fails"
        exit 2
else
        echo "Test successful"
        exit 0
fi


