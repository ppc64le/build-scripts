#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : mdp-toolkit
# Version       : 3.5
# Source repo   : https://github.com/mdp-toolkit/mdp-toolkit
# Tested on     : rhel_7.3
# Travis-Check  : True
# Language      : Python
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

export DEBIAN_FRONTEND=noninteractive

## Update source
yum update -y

## Install dependencies
yum install -y python git gcc-c++ python-devel.ppc64le \
    python-virtualenv python-test spicy
easy_install pip && pip install --upgrade setuptools \
    virtualenv mock ipython_genutils pytest traitlets

## Clone repo
git clone https://github.com/mdp-toolkit/mdp-toolkit

## Build and Install
cd mdp-toolkit
python setup.py install && python setup.py -q test -q
