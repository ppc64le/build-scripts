#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : clearcut 
# Version       : 1.0.9
# Source repo   : https://github.com/ibest/clearcut
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
# The clearcut installation provided in this script has not been fully optimized.
# To see how to optimize read the clearcut readme file

## Update Source
sudo yum update -y

#gcc dev tools
sudo yum groupinstall 'Development Tools' -y

## install dependencies
sudo yum install glibc-2.17-157.el7.ppc64le -y

# download and unpack
git clone https://github.com/ibest/clearcut.git
cd clearcut

# make
make
