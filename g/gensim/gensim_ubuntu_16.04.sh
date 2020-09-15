# ----------------------------------------------------------------------------
#
# Package	: gensim
# Version	: 3.4.0
# Source repo	: https://github.com/piskvorky/gensim.git
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
sudo apt-get install -y git g++ libatlas-base-dev libblas-dev subversion \
    python-dev

export LANG=en_US.UTF-8
sudo easy_install -U pip setuptools
pip install smart_open numpy scipy testfixtures

git clone https://github.com/piskvorky/gensim.git
cd gensim
python setup.py test
sudo python setup.py install
