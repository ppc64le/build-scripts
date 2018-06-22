# ----------------------------------------------------------------------------
#
# Package	: mongo csharp driver
# Version	: 2.6.1
# Source repo	: https://github.com/mongodb/mongo-csharp-driver
# Tested on	: ubuntu_16.04
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

apt-get update -y
apt-get install -y git autoconf libtool automake build-essential \
    gettext libtool-bin mono-devel wget tar mono-complete tzdata

wget  http://download.mono-project.com/sources/mono/mono-4.4.0.182.tar.bz2
tar xvf mono-4.4.0.182.tar.bz2
cd mono-4.4.0
./configure
make
# Actual install status is not important, hence always return true.
make install || true

yes | certmgr -ssl -m https://go.microsoft.com
yes | certmgr -ssl -m https://nugetgallery.blob.core.windows.net
yes | certmgr -ssl -m https://nuget.org

wget https://dist.nuget.org/win-x86-commandline/v3.3.0/nuget.exe
cp nuget.exe /usr/bin
echo 'exec /usr/local/bin/mono --runtime=v4.0.30319 --gc=sgen /usr/bin/nuget.exe "$@"' >> /usr/bin/NuGet
chmod u+x /usr/bin/NuGet
NuGet install mongocsharpdriver
