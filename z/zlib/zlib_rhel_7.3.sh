#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : zlib
# Version       : 1.2.8  
# Source repo   : http://www.zlib.net/fossils/           
# Tested on     : rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer    : Shane Barrantes <shane.barrantes@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintaine" of this script.
#
# ---------------------------------------------------------------------------- 

## Update Source
sudo yum update -y

working_dir=`pwd`
zlib_dir_name="/zlib-1.2.8"
zlib_path=$working_dir$zlib_dir_name

#download and unpack source code
wget http://www.zlib.net/fossils/zlib-1.2.8.tar.gz
tar -xzvf zlib-1.2.8.tar.gz
cd $zlib_path

#configure, make, make install
sudo ./configure ; sudo make test; sudo make install
