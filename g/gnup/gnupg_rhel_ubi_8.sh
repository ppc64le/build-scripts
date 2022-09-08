#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : gnupg
# Version       : V1-0-6
# Source repo   : https://github.com/gpg/gnupg.git
# Tested on     : UBI 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=gnupg
PACKAGE_VERSION=V1-0-6
PACKAGE_URL=https://github.com/gpg/gnupg.git


yum -y install bzip2
wget https://gnupg.org/ftp/gcrypt/npth/npth-1.6.tar.bz2
bzip2 -d npth-1.6.tar.bz2
tar -xvf npth-1.6.tar
cd npth-1.6
./configure
make
make install
make check

cd ..

wget https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.44.tar.bz2
bzip2 -d libgpg-error-1.44.tar.bz2
tar -xvf libgpg-error-1.44.tar
cd libgpg-error-1.44
./configure
make
make install
make check

cd ..

wget https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.10.0.tar.bz2
bzip2 -d libgcrypt-1.10.0.tar.bz2
tar -xvf libgcrypt-1.10.0.tar
cd libgcrypt-1.10.0
./configure
make
make install
make check

cd ..

wget https://gnupg.org/ftp/gcrypt/libksba/libksba-1.6.0.tar.bz2
bzip2 -d libksba-1.6.0.tar.bz2
tar -xvf libksba-1.6.0.tar
cd libksba-1.6.0
./configure
make
make install
make check

cd ..

wget https://gnupg.org/ftp/gcrypt/libassuan/libassuan-2.5.5.tar.bz2
bzip2 -d libassuan-2.5.5.tar.bz2
tar -xvf libassuan-2.5.5.tar
cd libassuan-2.5.5
./configure
make
make install
make check

cd ..


if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home
    	exit 0
fi

cd $PACKAGE_NAME

./configure
autoreconf --install --force
make -f build-aux/speedo.mk  native
make install
make check
