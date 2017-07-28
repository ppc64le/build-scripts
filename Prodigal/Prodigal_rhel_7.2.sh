#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : Prodigal 
# Version       : 2.6.3 
# Source repo   : https://github.com/hyattpd/Prodigal     
# Tested on     : rhel 7.2
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

# Update Source
sudo yum update -y

# gcc dev tools
sudo yum groupinstall 'Development Tools'

# install dependencies
sudo yum install glibc-2.17-157.el7.ppc64le -y

# download and unpack
git clone https://github.com/hyattpd/Prodigal.git
cd Prodigal

# make
make
