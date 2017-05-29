# ----------------------------------------------------------------------------
#
# Package       : vincent
# Version       : 0.4.4
# Source repo   : https://github.com/wrobstory/vincent
# Tested on     : rhel_7.3
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
sudo yum update -y

## Install dependencies
sudo yum groupinstall -y "Development Tools"
sudo yum install -y  python  git gcc-c++ python-devel python-setuptools
sudo easy_install pip && sudo pip install --upgrade setuptools virtualenv

## Clone repo
git clone https://github.com/wrobstory/vincent

## Build and Install
cd vincent/
sudo yum install -qq -y libgfortran.ppc64le atlas.ppc64le atlas-static.ppc64le numpy.ppc64le && \
	sudo pip install ipython mock pandas flake8 pytest nose ptyprocess && sudo pip install -r requirements.txt && \
	sudo python setup.py install && export TOXENV=py27 && sudo -E python setup.py -q test -q && \
	sudo pip install -U setuptools && sudo -E nosetests && \
	sudo pip uninstall -y ipython mock pandas flake8 pytest nose ptyprocess && \
	sudo yum remove -y git python-numpy && sudo yum -y autoremove
