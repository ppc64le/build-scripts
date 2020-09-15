#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package	: cloudpickle
# Version	: 0.5.2
# Source repo	: https://github.com/cloudpipe/cloudpickle.git
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Meghali Dhoble <dhoblem@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
export DEBIAN_FRONTEND=noninteractive

## Install dependencies
sudo apt-get update -y 
sudo apt-get install -y python deltarpm python-setuptools python-dev \
  python-pip gcc cpp cpp-powerpc-linux-gnu make build-essential \
  python3-gdbm git

sudo pip install -U pip && \
  sudo pip install tox py pytest coverage pytest-cov pbr mock argparse codecov

## clone the source 
git clone https://github.com/cloudpipe/cloudpickle.git 
cd cloudpickle

## Build and Install
/bin/bash -l -c "sudo python setup.py install && PYTHONPATH='.:tests' py.test"

