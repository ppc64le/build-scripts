# -----------------------------------------------------------------------------
#
# Package	: furo
# Version	: 2020.12.30.beta24
# Source repo	: https://github.com/pradyunsg/furo
# Tested on	: ubi 8.5
# Language      : python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -e

PACKAGE_NAME="furo"
PACKAGE_VERSION=${1:-"2020.12.30.beta24"}
PACKAGE_URL="https://github.com/pradyunsg/furo"

# creating non-root user
useradd -p "" -G wheel ubi
dnf install sudo -y
sudo -i -u ubi bash <<EOF
set -e 
sudo dnf install python38  python38-devel python27 python2-devel  libffi-devel  gcc gcc-c++ git  make -y

# install nvm and node 14
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 14
# installing packages

cd ~
git clone $PACKAGE_URL $PACKAGE_NAME
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION  
python3 -m venv ~/furo_venv_py38
source ~/furo_venv_py38/bin/activate
python -m pip install --upgrade pip
pip install build  nox flit
python -m build
flit install
npm install
npx browserslist@latest --update-db
npm install -g gulp-cli
nox -s docs
./node_modules/.bin/gulp build
flit build
EOF
