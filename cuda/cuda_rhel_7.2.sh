#!/bin/bash
#-----------------------------------------------------------------------------
#
# package       : cuda 
# Version       : 7
# Source repo   : https://developer.nvidia.com/cuda-downloads 
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
sudo yum groupinstall 'Development Tools' -y

# install 
sudo rpm -i cuda-repo-rhel7-8-0-local-ga2v2-8.0.61-1.ppc64le.rpm
sudo yum clean all
sudo yum install cuda
