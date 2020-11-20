# ----------------------------------------------------------------------------
#
# Package	: mongo csharp driver
# Version	: 2.6.1
# Source repo	: https://github.com/mongodb/mongo-csharp-driver
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies
yum update -y
yum install -y git autoconf libtool automake cmake \
    gettext libtool wget tar bzip2 make gcc-c++

wget download.mono-project.com/sources/mono/mono-4.4.0.182.tar.bz2
tar xjf mono-4.4.0.182.tar.bz2
cd mono-4.4.0
./configure
make
make install

echo "updating certificates"
yes | certmgr -ssl -m https://go.microsoft.com
yes | certmgr -ssl -m https://nugetgallery.blob.core.windows.net
yes | certmgr -ssl -m https://nuget.org

echo "downloading nuget and testing driver"
wget https://dist.nuget.org/win-x86-commandline/v3.3.0/nuget.exe
cp nuget.exe /usr/bin
echo 'exec /usr/local/bin/mono --runtime=v4.0.30319 --gc=sgen /usr/bin/nuget.exe "$@"' | tee -a /usr/bin/NuGet
chmod u+x /usr/bin/NuGet
/usr/bin/NuGet install mongocsharpdriver
