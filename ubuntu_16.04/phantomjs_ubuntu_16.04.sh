# ----------------------------------------------------------------------------
#
# Package	: Phantomjs
# Version	: 2.1.1
# Source repo	: https://github.com/ariya/phantomjs/
# Tested on	: ubuntu_16.04
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

# Install all dependencies.
sudo apt-get update -y
sudo apt-get install -y build-essential g++ flex bison gperf \
        ruby perl libsqlite3-dev libfontconfig1-dev libicu-dev \
        libfreetype6 libssl-dev libpng-dev libjpeg-dev python \
        libx11-dev libxext-dev git
sudo apt-get install -y "^libxcb.*" libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev

# Clone PhantomJS code and build it.
wrkdir=`pwd`
git clone http://github.com/ariya/phantomjs.git
cd phantomjs && git checkout 2.1.1 && \
   git submodule init && git submodule update && ./build.py -c
echo "phantomjs build completed."

# Start automated tests.
echo "starting tests"
cd $wrkdir/phantomjs && cd test && python run-tests.py
