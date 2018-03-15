# ----------------------------------------------------------------------------
#
# Package	: sudosh2
# Version	: master (commit #a75427f183749f31ae6297c13d189af6d46c6e66)
# Source repo	: https://github.com/squash/sudosh2
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
sudo zypper install -y wget vim git make gcc gcc-c++

git clone https://github.com/squash/sudosh2
cd sudosh2

wget -O config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
wget -O config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'

./configure
make
sudo make install

