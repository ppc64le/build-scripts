# ----------------------------------------------------------------------------
#
# Package	: caffe
# Version	: 1.0.0-rc5
# Source repo	: https://github.com/BVLC/caffe.git
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
sudo apt-get install -y g++ gcc make cmake python-dev protobuf-compiler \
    libgoogle-glog-dev libgflags-dev libmirprotobuf3 libprotobuf-dev \
    libleveldb-dev libsnappy-dev libopencv-dev libhdf5-serial-dev \
    liblmdb-dev libatlas-base-dev doxygen python-pytest python-numpy \
    git libncurses5-dev libboost1.58-all-dev

# Build caffe.
git clone https://github.com/BVLC/caffe.git
cd caffe && \
sed -i.bak '/pycaffe/d' CMakeLists.txt && \
cmake . && \
make && \
make runtest
make install
