# ----------------------------------------------------------------------------
#
# Package	: rootsh
# Version	: 1.5.4
# Source repo	: https://sourceforge.net/projects/rootsh/
# Tested on	: sles_12_sp2
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install all dependencies.
sudo zypper refresh
sudo zypper install -y wget git make gcc gcc-c++ autoconf libtool

#Build and test the source
git clone https://git.code.sf.net/p/rootsh/code rootsh
cd rootsh
sh bootstrap.sh
cd config
wget -O config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
wget -O config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
cd ..
./configure
make
sh test.sh
sudo make install
