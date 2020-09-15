# ----------------------------------------------------------------------------
#
# Package	: spidermonkey JS engine
# Version	: 20150223
# Source repo	: https://github.com/mozilla/gecko-dev.git
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y git zip unzip mercurial g++ make autoconf2.13 \
    yasm libgtk2.0-dev libglib2.0-dev libdbus-1-dev libdbus-glib-1-dev \
    libasound2-dev libcurl4-openssl-dev libiw-dev libxt-dev mesa-common-dev \
    libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev libpulse-dev m4 \
    flex ccache

# Clone and build source.
git clone https://github.com/mozilla/gecko-dev.git
cd gecko-dev
git checkout B2G_2_2_20150223_MERGEDAY
cd js/src
autoconf2.13
mkdir build_OPT.OBJ
cd build_OPT.OBJ
../configure
make
sudo make install
make check
