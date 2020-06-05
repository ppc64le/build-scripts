# ----------------------------------------------------------------------------
#
# Package       : ansi-html
# Version       : 0.0.7
# Source repo   : https://github.com/Tjatse/ansi-html
# Tested on     : Ubuntu 18.04
# Script License: Apache License, Version 2 or later
# Maintainer    : Ryan D'Mello <ryan.dmello1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

export IBM_POWERAI_LICENSE_ACCEPT=yes
export PATH=${PATH}:$HOME/conda/bin
export PYTHON_VERSION=3.6
export LANG=en_US.utf8
export PACKAGE_VERSION=0.0.7
export PACKAGE_NAME=ansi-html
export PACKAGE_URL=https://github.com/Tjatse/ansi-html
export QT_QPA_PLATFORM=offscreen
WDIR=`pwd`

apt-get update && apt-get upgrade -y && apt-get install -y curl git xz-utils \
    python unzip build-essential socat openssl wget \
    libsqlite3-0 libfontconfig1 libicu-dev libfreetype6 libssl1.0.0 \
    libpng-dev libjpeg62 python libx11-6 libxext6 \
    libfreetype6-dev libcairo2-dev pkg-config libjpeg62-dev \
    libzmq3-dev jq phantomjs && \
    rm -rf /var/cache/apt/*

wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
sh Miniconda3-latest-Linux-ppc64le.sh -u -b -p $HOME/conda
$HOME/conda/bin/conda update -y -n base conda
conda create -n ${PACKAGE_NAME} -y python=${PYTHON_VERSION}
conda init bash
eval "$(conda shell.bash hook)"
conda activate ${PACKAGE_NAME}
conda install -y -c "conda-forge" nodejs

export PATH=$PATH:`pwd`/node_modules/.bin/
npm config set registry http://registry.npmjs.org/ && npm install node-gyp && node-gyp install

npm install mocha grunt yarn

git clone ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${PACKAGE_NAME}

npm install && npm test