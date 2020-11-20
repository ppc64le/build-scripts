# ----------------------------------------------------------------------------
#
# Package       : bashdb
# Version       : 4.2-0.8, 4.4-1.0.1
# Source repo   : https://sourceforge.net/projects/bashdb/files/bashdb/4.2-0.8/bashdb-4.2-0.8.tar.gz
# Tested on     : RHEL_7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

if [ "$#" -gt 0 ]
then
    VERSION=$1
else
    VERSION="4.2-0.8"
fi

#Install dependecies
sudo yum update -y
sudo yum groups mark install "Development Tools"
sudo yum groups mark convert "Development Tools"
sudo yum groupinstall -y "Development Tools"
sudo yum install -y wget tar unzip

#Build and test bashdb
wget https://sourceforge.net/projects/bashdb/files/bashdb/${VERSION}/bashdb-${VERSION}.tar.gz
tar -zxvf bashdb-${VERSION}.tar.gz
cd bashdb-${VERSION}

wget -O config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
wget -O config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'

./configure --prefix=/usr

make
#Note: one test is failing for 4.2-0.8 version in "root" environment, however
#the same fails on Intel as well.
make check
sudo make install
