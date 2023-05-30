#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : AutoMapper.Collection
# Version       : v9.0.0
# Source repo   : https://github.com/AutoMapper/AutoMapper.Collection.git
# Tested on     : UBI 8.7
# Language      : C#
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ashutosh Jadhav <Ashutosh.Jadhav2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=AutoMapper.Collection
PACKAGE_VERSION=${1:-v9.0.0}
PACKAGE_URL=https://github.com/AutoMapper/AutoMapper.Collection.git
DOTNET_VERSION=7.0

yum -y update && yum install -y  "dotnet-sdk-$DOTNET_VERSION" git
SDK_VERSION=$(dotnet --version)

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#update target frameworks and EntityFramework
for file in `find . -type f -name "*.csproj"`;
do
        sed -i '/^[[:blank:]]*<PackageReference Include="EntityFramework" Version="*"/c\<PackageReference Include="EntityFramework" Version="6.4" />' $file  ;
        sed -i '/^[[:blank:]]*<TargetFrameworks>/c\<TargetFrameworks>net'"$DOTNET_VERSION"'</TargetFrameworks>' $file  ;
done

#update test sdk version to 17.5.0 (from this version onwards power arch is supported
for file in `grep "<PackageReference Include=\"Microsoft.NET.Test.Sdk\"" -rl `;
do
        sed -i '/^[[:blank:]]*<PackageReference Include=\"Microsoft.NET.Test.Sdk\"/c\<PackageReference Include=\"Microsoft.NET.Test.Sdk\" Version=\"17.5.0\" />' $file  ;
done

#Building the package
if ! dotnet build; then
        echo "Build fails"
        exit 1
else
        echo "Build successful.. Running tests"
fi

#go to test folder and run test cases
if ! dotnet test; then
        echo "Tests fails"
        exit 2
else
        echo "Test successful"
        exit 0
fi
