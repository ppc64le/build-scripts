# ----------------------------------------------------------------------------
#
# Package	: CUDA-runtime
# Version	: 8.0
# Source repo	: https://developer.nvidia.com/cuda-downloads
# Tested on	: ubuntu_16.04
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

# Install dependencies.
sudo apt-get update -y
sudo apt-get install -y make wget build-essential libncurses5 libncurses5-dev \
    gcc-4.8 g++-4.8 linux-image-generic linux-headers-generic

# Download the source repository.
wget https://developer.nvidia.com/compute/cuda/8.0/prod/local_installers/cuda-repo-ubuntu1604-8-0-local_8.0.44-1_ppc64el-deb
sudo dpkg -i cuda-repo-ubuntu1604-8-0-local_8.0.44-1_ppc64el-deb
sudo apt-get update -y
sudo apt-get install -y cuda
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 10
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Build the source.
/usr/local/cuda/bin/cuda-install-samples-8.0.sh ~
cd ~/NVIDIA_CUDA-8.0_Samples/0_Simple/vectorAdd && make
