# ----------------------------------------------------------------------------
#
# Package       : inflection
# Version       : 0.3.1
# Source repo   : https://github.com/jpvanhal/inflection
# Tested on     : Ubuntu_16.04
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
sudo apt-get install -y git virtualenv pandoc python-setuptools python-dev locales locales-all
sudo easy_install pip && sudo pip install --upgrade setuptools virtualenv mock ipython_genutils pytest traitlets

## Clone repo
git clone https://github.com/jpvanhal/inflection

## Build and Install
cd inflection/
sudo pip install -r requirements.txt && sudo flake8 . && sudo isort --recursive --diff . && sudo isort --recursive --check-only . && sudo py.test