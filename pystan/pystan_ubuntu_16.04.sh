# ----------------------------------------------------------------------------
#
# Package	: pystan
# Version	: 2.16.0.0
# Source repo	: https://github.com/stan-dev/pystan.git
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
sudo apt-get install -y build-essential software-properties-common sudo \
    python-virtualenv python python-dev python-pip python-scipy git wget \
    xz-utils curl unzip socat libsqlite3-0 libfontconfig1 libicu55 \
    libatlas-base-dev libopencv-dev libfreetype6-dev libssl1.0.0 libpng12-0 \
    libjpeg62 libx11-6 libxext6 gcc gfortran libatlas-base-dev libopencv-dev

sudo pip install --upgrade pip
sudo pip install --upgrade setuptools
sudo pip install --upgrade git+git://github.com/cython/cython@master
sudo pip install ez_setup
sudo pip install numpy six
sudo apt-get install pkg-config

git clone -b master https://github.com/stan-dev/pystan.git
cd pystan
git submodule update --init --recursive
python setup.py install
cd continuous_integration
wget https://repo.continuum.io/miniconda/Miniconda-3.16.0-Linux-ppc64le.sh -O miniconda.sh
bash miniconda.sh -b config --set always_yes yes --set changeps1 no \
    --set show_channel_urls true
bash test_script.sh
