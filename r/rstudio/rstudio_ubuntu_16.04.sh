# ----------------------------------------------------------------------------
#
# Package	: rstudio
# Version	: 1.1.447
# Source repo	: https://github.com/rstudio/rstudio
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

sudo apt-get -y update
sudo apt-get -y install ant apparmor-utils autotools-dev build-essential \
    ca-certificates cmake fakeroot file g++ git haskell-platform libapparmor1 \
    libbz2-dev libcurl4-openssl-dev libedit2 libicu-dev libpam-dev \
    libpango1.0-dev libssl-dev libxslt1-dev libboost-all-dev openjdk-8-jdk \
    pkg-config psmisc python-dev python-setuptools r-base r-base-dev pandoc \
    pandoc-citeproc unzip uuid-dev zlib1g-dev

WDIR=`pwd`

git clone https://github.com/rstudio/rstudio
cd $WDIR/rstudio/dependencies/linux
./install-dependencies-debian --exclude-qt-sdk

# Build and Install RStudio
mkdir -p $WDIR/rstudio/build
cd $WDIR/rstudio/build
cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release
sudo make install
