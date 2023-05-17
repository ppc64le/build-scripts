#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: CsvHelper
# Version	: 30.0.1
# Source repo	: https://github.com/JoshClose/CsvHelper.git
# Tested on	: UBI 8.7
# Language      : C#
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapana Khemkar <Sapana.Khemkar@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=CsvHelper
PACKAGE_VERSION=${1:30.0.1}
PACKAGE_URL=https://github.com/JoshClose/CsvHelper.git

yum -y update && yum install -y dotnet-sdk-7.0 git

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#update dotnet version to  be used
sed -i '/"version":/c\"version": "7.0.100"' global.json

#update target frameworks to net7.0
for i in `find . -type f -name "*.csproj"`;
do
	echo "updating target frameworks for $i";
	sed -i '/^[[:blank:]]*<TargetFrameworks>/c\<TargetFrameworks>net7.0</TargetFrameworks>' $i  ;
done

#update test sdk version to 17.5.0 (from this version onwards power arch is supported
for i in `grep "<PackageReference Include=\"Microsoft.NET.Test.Sdk\"" -rl `;
do
	sed -i '/^[[:blank:]]*<PackageReference Include=\"Microsoft.NET.Test.Sdk\"/c\<PackageReference Include=\"Microsoft.NET.Test.Sdk\" Version=\"17.5.0\" />' $i  ;
done

cd tests/CsvHelper.Tests 
dotnet test




