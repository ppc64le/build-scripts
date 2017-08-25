# ----------------------------------------------------------------------------
#
# Package       : torch
# Version       : 7.0
# Source repo   : https://github.com/PPC64/torch-distro.git
# Tested on     : ubuntu_16.04
# Script License: Apache License
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update
sudo apt-get install -y libzmq3-dev libssl-dev python-zmq luarocks git

sudo luarocks install lzmq
sudo luarocks install penlight
sudo luarocks install env
sudo luarocks install luafilesystem

git clone https://github.com/PPC64/torch-distro.git ~/torch --recursive
cd ~/torch; bash install-deps
sudo ./install.sh -b
exec bash
. /root/.bashrc
sudo luarocks install image
luarocks make
