#!/bin/bash
#-----------------------------------------------------------------------------
# 
# package       : canu
# Version       : 1.2
# Source repo   : https://github.com/marbl/canu.git 
# Tested on     : Centos_7.3 
# Script License: Apache License, Version 2 or later 
# Maintainer    : Shane Barrantes <Shane.Barrantes@ibm.com>
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

#gcc dev tools
sudo yum groupinstall 'Development Tools'

## install deppendencies
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install libgomp-4.8.5-11.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y
sudo yum install boost-devel -y

# download and unpack
git clone https://github.com/marbl/canu.git
cd canu/src
make
