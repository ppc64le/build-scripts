#! /bin/env bash
# ----------------------------------------------------------------------------
#
# Package	: json-content-demux
# Version	: 0.2.0
# Source repo	: https://github.com/twolfson/json-content-demux
# Tested on	: ubuntu_18.04
# Script License: Apache 2.0 or later
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
wget https://github.com/twolfson/json-content-demux/archive/0.2.0.tar.gz
tar xvfz 0.2.0.tar.gz
mv json-content-demux-0.2.0 json-content-demux
cd json-content-demux
npm install jshint nodeunit
npm test
