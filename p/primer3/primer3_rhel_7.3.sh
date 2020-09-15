#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : primer3
# Version       : 2.2.3
# Source repo   : sourceforge.net/projects/primer3/files/primer3/2.2.3/       
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

# Update Source
sudo yum update -y

# gcc dev tools
sudo yum groupinstall 'Development Tools' -y

# install dependencies
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y

# download and unpack
wget https://downloads.sourceforge.net/project/primer3/primer3/2.2.3/primer3-2.2.3.tar.gz
tar -xzvf primer3-2.2.3.tar.gz
cd primer3-2.2.3/src

# make
make all ; make test
