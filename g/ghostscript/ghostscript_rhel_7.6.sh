# ----------------------------------------------------------------------------
#
# Package       : ghostscript
# Version       : 9.52
# Source repo   : https://github.com/ArtifexSoftware/ghostpdl-downloads
# Tested on     : RHEL 7.6, RHEL 7.7
# Script License: Apache License, Version 2 or later
# Maintainer    : Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

yum update -y
yum install -y libjpeg-turbo-devel libpng-devel wget gcc-c++ make autoconf tar gzip

wget https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs952/ghostscript-9.52.tar.gz
tar -zxvf ghostscript-9.52.tar.gz
cd ghostscript-9.52
rm -rf libpng 
sh autogen.sh
./configure
make
make install
