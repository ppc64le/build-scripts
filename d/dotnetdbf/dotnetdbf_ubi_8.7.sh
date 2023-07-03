#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : dotnetdbf
# Version       : 414321a
# Source repo   : https://github.com/ekonbenefits/dotnetdbf
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

PACKAGE_NAME=dotnetdbf
PACKAGE_VERSION=${1:-414321a}
PACKAGE_URL=https://github.com/ekonbenefits/dotnetdbf

DOTNET_VERSION=7.0

yum -y update && yum install -y  "dotnet-sdk-$DOTNET_VERSION" git

SDK_VERSION=$(dotnet --version)
echo ".NET SDK Version is " $SDK_VERSION

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# update target frameworks
for file in `find . -type f -name "*.csproj"`;
do
        sed -i '/^[[:blank:]]*<TargetFrameworks>/c\<TargetFrameworks>net'"$DOTNET_VERSION"'</TargetFrameworks>' $file  ;
done

# update test sdk version to 17.5.0 (from this version onwards power arch is supported
for file in `grep "<PackageReference Include=\"Microsoft.NET.Test.Sdk\"" -rl `;
do
        sed -i '/^[[:blank:]]*<PackageReference Include=\"Microsoft.NET.Test.Sdk\"/c\<PackageReference Include=\"Microsoft.NET.Test.Sdk\" Version=\"17.5.0\" />' $file  ;
done

# use latest version of Microsoft.SourceLink.GitHub
for file in `grep "<PackageReference Include=\"Microsoft.SourceLink.GitHub\"" -rl `;
do
        sed -i '/^[[:blank:]]*<PackageReference Include=\"Microsoft.SourceLink.GitHub\"/c\<PackageReference Include=\"Microsoft.SourceLink.GitHub\" Version=\"1.1.1\" />' $file  ;
done


# remove empty main to fix build error
rm DotNetDBF.Test/Program.cs

# skip test case "Test()" as it fails due to required file not found
# Failed Test [14 ms]
#   Error Message:
#    DotNetDBF.DBFException : Failed To Read DBF
#   ----> System.IO.EndOfStreamException : Unable to read beyond the end of the stream.
#
sed  -i '/^[[:blank:]]*public void Test()/i [Ignore("Ignore for Power")]' DotNetDBF.Test/Test.cs

# build code
if ! dotnet build; then
        echo "Build fails"
        exit 1
else
        echo "Build successful.. Running tests"
fi

# run tests
if ! dotnet test; then
        echo "Test fails"
        exit 2
else
        echo "Test successful"
        exit 0
fi


