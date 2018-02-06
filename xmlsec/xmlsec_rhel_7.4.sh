# ----------------------------------------------------------------------------
# Package       : xmlsec
# Version       : 1_2_25
# Source repo   : https://github.com/lsh123/xmlsec
# Tested on     : rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

#Install dependencies needed for building
sudo yum -y update
sudo yum -y install autoconf \
        libtool \
        make \
        openssl-devel \
        libxml2-devel \
        libxslt-devel \
	libtool-ltdl-devel \
        pkgconfig \
 	git

#Clone the git repo, build and test the source
git clone  https://github.com/lsh123/xmlsec 
cd xmlsec
sh autogen.sh
sudo make
sudo make check
sudo make install
sudo make clean 
cd ..
rm -rf xmlsec

#NOTE
#Libraries have been installed in:
#   /usr/local/lib
