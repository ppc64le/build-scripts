# ----------------------------------------------------------------------------
#
# Package       : bsdiff4
# Version       : 1.1.4
# Source repo   : https://github.com/ilanschnell/bsdiff4
# Tested on     : ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Archa Bhandare <barcha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

## Update source
sudo apt-get update -y

## Install dependencies
sudo apt-get install -y git python gcc libzmq-dev libsodium-dev python-pip cython libpython-all-dev

## Clone repo
git clone https://github.com/ilanschnell/bsdiff4.git

## Build and Install
cd bsdiff4/
sudo python setup.py build_ext --inplace && sudo python -c "import bsdiff4; bsdiff4.test()" && sudo rm -rf build dist && sudo rm -f bsdiff4/*.o bsdiff4/*.so bsdiff4/*.pyc && sudo rm -rf bsdiff4/__pycache__ *.egg-info
