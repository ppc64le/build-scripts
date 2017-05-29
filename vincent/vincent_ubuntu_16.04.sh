# ----------------------------------------------------------------------------
#
# Package       : vincent
# Version       : 0.4.4
# Source repo   : https://github.com/wrobstory/vincent
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
sudo apt-get install -y build-essential software-properties-common
sudo apt-get install -y git python-setuptools python-dev locales locales-all
sudo easy_install pip && sudo pip install --upgrade setuptools virtualenv

## Clone repo
git clone https://github.com/wrobstory/vincent

## Build and Install
cd vincent/
sudo apt-get install -qq gfortran libatlas-base-dev python-numpy && \
	sudo pip install ipython mock pandas flake8 pytest nose ptyprocess && sudo pip install -r requirements.txt && \
	sudo python setup.py install && export TOXENV=py27 && sudo -E python setup.py -q test -q && \
	sudo pip install -U setuptools && sudo -E nosetests && \
	sudo pip uninstall -y ipython mock pandas flake8 pytest nose ptyprocess && \
	sudo apt-get remove -y git && sudo apt-get -y autoremove
