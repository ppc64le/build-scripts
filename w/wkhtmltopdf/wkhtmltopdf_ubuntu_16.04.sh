# ----------------------------------------------------------------------------
#
# Package	: wkhtmltopdf
# Version	: 0.12.5-dev
# Source repo	: https://github.com/wkhtmltopdf/wkhtmltopdf
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
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
sudo apt-get install python \
        make \
        gcc \
        g++ \
        libx11-dev \
        libxext-dev \
        libxtst-dev \
        libjpeg-turbo8-dev \
        libpng16-dev \
        git \
	libxrender-dev \
	libssl-dev -y

git clone --recursive https://github.com/wkhtmltopdf/wkhtmltopdf.git
cd wkhtmltopdf
export WKHTMLTOX_CHROOT=`pwd`
scripts/build.py posix-local -debug
