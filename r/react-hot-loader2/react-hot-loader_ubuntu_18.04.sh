#! /bin/env bash
# ----------------------------------------------------------------------------
#
# Package	: react-hot-loader
# Version	: 4.13.0
# Source repo	: https://github.com/gaearon/react-hot-loader
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

NVM_DIR="/root/.nvm"
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update -y
sudo apt-get install -y \
	yarn \
	sudo \
	software-properties-common \
	wget \
	curl \
;
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash \
&& . $NVM_DIR/nvm.sh \
    && nvm install 8 \
    && nvm alias default 8 \
    && nvm use default

wget https://github.com/gaearon/react-hot-loader/archive/v4.13.0.tar.gz
tar xvfz v4.13.0.tar.gz
mv react-hot-loader-4.13.0 react-hot-loader
cd react-hot-loader
yarn --frozen-lockfile
yarn ci
