#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : cutadapt
# Version       : 1.8.1  
# Source repo   : https://pypi.python.org/pypi/cutadapt/1.8.1  
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
sudo yum install python-devel -y
sudo yum install python-lxml -y

# download
wget https://pypi.python.org/packages/62/bc/77da8a0f0c162831fdccb89306e65cbe14bab7eb72c150afb8e197fa262f/cutadapt-1.8.1.tar.gz
tar -xzvf cutadapt-1.8.1.tar.gz
cd cutadapt-1.8.1

# install
sudo python setup.py install 
