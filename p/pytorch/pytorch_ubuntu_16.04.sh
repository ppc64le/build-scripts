#!/bin/bash
#-----------------------------------------------------------------------------
# 
# package       : pytorch 
# Version       : master 
# Source repo   : https://github.com/pytorch/pytorch
# Tested on     : Ubuntu 16.04
# Script License: Apache License, Version 2 or later 
# Maintainer    : Vaibhav Sood <vaibhavs@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------- 

#Please install CUDA 8.0 for ppc64le before proceeding

sudo apt-get update 
sudo apt-get install -y --no-install-recommends git
	
git config --global http.sslVerify false
git clone https://github.com/avmgithub/pytorch_builder.git
cd pytorch_builder
chmod +x build_nimbix.sh
./build_nimbix.sh pytorch HEAD master foo 3 LINUX
