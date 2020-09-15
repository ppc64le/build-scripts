# ----------------------------------------------------------------------------
#
# Package	: ffmpeg
# Version	: N-85266-g1229007
# Source repo	: https://github.com/FFmpeg/FFmpeg
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
sudo apt-get install -y  git make gcc

# build and install ffmpeg.
git clone https://github.com/FFmpeg/FFmpeg
cd FFmpeg
./configure && \
make && \
make check && \
sudo make install
