#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: {package_name}
# Version	: {package_version}
# Source repo	: {package_url}
# Tested on	: {distro_name} {distro_version}
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_URL =https://github.com/gpg/gnupg
PACKAGE_NAME = gnupg
PACKAGE_VERSION = 2.2.28 

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
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
    	exit 0
fi

cd $PACKAGE_NAME

./configure
autoreconf --install --force
make -f build-aux/speedo.mk  native
make install
make check
