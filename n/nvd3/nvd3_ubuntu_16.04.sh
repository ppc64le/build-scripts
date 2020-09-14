# ----------------------------------------------------------------------------
#
# Package       : NVD3
# Version       : 1.8.6
# Source repo   : https://github.com/novus/nvd3.git
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin.bash

# Install Dependecies
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823
sudo apt-get update -y
sudo apt-get install -y dirmngr nodejs npm wget python gcc g++ make git

sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g grunt grunt-cli bower

# build nvd3
git clone https://github.com/novus/nvd3.git
cd $PWD/nvd3
sudo npm install
grunt production
