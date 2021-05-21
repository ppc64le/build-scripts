#!/bin/env bash
# ----------------------------------------------------------------------------
#
# Package	: pyyaml
# Version	: 5.3.1
# Source repo	: https://github.com/yaml/pyyaml
# Tested on	: ubuntu_18.04
# Script License: MIT License
# Maintainer	: eshant.gupta@ibm.com
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
TOXENV=py38
DEBIAN_FRONTEND=noninteractive
sudo apt-get update && apt-get upgrade -y && \
sudo add-apt-repository ppa:deadsnakes/ppa -y && \
sudo apt-get update -y \
sudo apt-get install -yqq --no-install-suggests \
        build-essential libtool pkg-config \
        autoconf python3.8 python3.8-dev git && \
curl https://bootstrap.pypa.io/get-pip.py | sudo python3.8 && \
sudo apt-get clean && \
python3 -m pip install --upgrade pip setuptools wheel --no-cache-dir && \
python3 -m pip install cython tox --no-cache-dir && \
#git clone https://github.com/ezeeyahoo/pyyaml.git pyyaml && \
#git clone https://github.com/yaml/libyaml.git /tmp/libyaml && \
wget https://github.com/yaml/pyyaml/archive/5.3.1.zip && \
unzip 5.3.1.zip && \
mv pyyaml-5.3.1 pyyaml
wget https://github.com/yaml/libyaml/archive/0.2.5.zip && \
unzip 0.2.5.zip && \
mv libyaml-0.2.5 /tmp/libyaml
cd /tmp/libyaml && \
git reset --hard 0.2.2 && \
./bootstrap && \
./configure && \
make && \
make test-all && \
ldconfig && \
cd && \
cd pyyaml && \
tox
exit 0
