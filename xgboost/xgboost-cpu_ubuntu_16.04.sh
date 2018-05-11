# ----------------------------------------------------------------------------
#
# Package	: xgboost
# Version	: 0.71
# Source repo	: https://github.com/dmlc/xgboost
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

sudo apt-get update -y
sudo apt-get install -y wget git cmake python python-dev python-nose \
    python-setuptools python-numpy python-sklearn liblapack-dev graphviz
sudo easy_install -U numpy scikit-learn sklearn graphviz pandas

git clone --recursive https://github.com/dmlc/xgboost
cd xgboost && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release && make -j
cd ..
cp build/librabit.a rabit/lib
cd python-package
sudo python setup.py install
cd ..
nosetests tests/python
