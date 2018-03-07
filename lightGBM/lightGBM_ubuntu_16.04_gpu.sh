# ----------------------------------------------------------------------------
#
# Package	: LightGBM
# Version	: 2.1.0
# Source repo	: https://github.com/Microsoft/LightGBM
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Priya Seth <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

sudo apt-get update -y

#Install OpenCL development environment
sudo apt-get install -y nvidia-opencl-icd-375 nvidia-opencl-dev opencl-headers

#Install necessary building tools and dependencies
sudo apt-get install -y git vim python-dev cmake build-essential libboost-dev libboost-system-dev libboost-filesystem-dev liblapack-dev

#Compile light GBM with GPU support
git clone --recursive https://github.com/Microsoft/LightGBM
cd LightGBM
mkdir build ; cd build

#Disable altivec support
cmake -DUSE_GPU=1 -DCMAKE_C_FLAGS="-mno-altivec -mno-vsx" -DCMAKE_CXX_FLAGS="-mno-altivec -mno-vsx" ..
make -j$(nproc)
cd ..

#Install Python Interface (optional)
sudo apt-get install -y python-pip python-numpy 
sudo pip install --upgrade pip

sudo pip install setuptools numpy scipy -U
sudo pip install scikit-learn -U
cd python-package/
sudo python setup.py install --precompile
cd ..

#Execute automated tests
sudo pip install pytest nose pandas
pytest
