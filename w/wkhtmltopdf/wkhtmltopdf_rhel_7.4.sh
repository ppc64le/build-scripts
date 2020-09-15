# ----------------------------------------------------------------------------
#
# Package       : wkhtmltopdf
# Version       : 0.12.5-dev
# Source repo   : https://github.com/wkhtmltopdf/wkhtmltopdf
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

sudo yum -y update 
sudo yum -y install python \
	make \
	gcc \
	gcc-c++ \
	libX11-devel \
	libXext-devel \
	libXtst-devel \
	libjpeg-turbo-devel \
	libpng-devel \
	openssl-devel \
	libXrender-devel \
	git

git clone --recursive https://github.com/wkhtmltopdf/wkhtmltopdf.git
cd wkhtmltopdf
export WKHTMLTOX_CHROOT=`pwd`
scripts/build.py posix-local -debug
