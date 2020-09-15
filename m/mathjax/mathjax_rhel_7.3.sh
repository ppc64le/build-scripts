# ----------------------------------------------------------------------------
#
# Package	: MathJax
# Version	: 1.1
# Source repo	: https://github.com/mathjax/MathJax.git
# Tested on	: rhel_7.3
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Update source.
sudo yum update -y
sudo yum install -y gcc-c++ make python git

WDIR=`pwd`
git clone https://github.com/ibmruntimes/node.git nodeInstall
cd nodeInstall
./configure
make
sudo make install

# Build and Install.
cd $WDIR
git clone https://github.com/mathjax/MathJax.git
cd MathJax
sudo npm install
npm test
