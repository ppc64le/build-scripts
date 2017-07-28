#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : novelseq
# Version       : 1.0.2    
# Source repo   : https://sourceforge.net/projects/novelseq/files/      
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
sudo yum install sqlite-3.7.17-8.el7.ppc64le -y
sudo yum install glibc-2.17-157.el7.ppc64le -y
sudo yum install libgcc-4.8.5-11.el7.ppc64le -y
sudo yum install libgomp-4.8.5-11.el7.ppc64le -y

# download and unpack
wget https://downloads.sourceforge.net/project/novelseq/novelseq-1.0.2.tar.gz
tar -xzvf novelseq-1.0.2.tar.gz
cd novelseq-upload

# make
ls -1| grep cpp | sed 's/.cpp//g' | xargs -i00 g++ 00.cpp -o 00; gcc -std=c99 sortString.c -o sortString; gcc fs-fa.c -o fs-fa
