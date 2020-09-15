# ----------------------------------------------------------------------------
#
# Package	: CodeMirror
# Version	: 5.33.1
# Source repo	: https://github.com/codemirror/CodeMirror
# Tested on	: ubuntu_16.04
# Script License: Apache License, Version 2 or later
# Maintainer	: Yugandha Deshpande <yugandha@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

sudo apt-get update
sudo apt-get install wget bzip2 git -y
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 

sudo mv phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin
rm -rf phantomjs-2.1.1-linux-ppc64.tar.bz2
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
source $HOME/.nvm/nvm.sh
nvm install stable
nvm use stable

git clone https://github.com/codemirror/CodeMirror
cd CodeMirror
npm install

## NOTE ##
# Tests are being disabled as tests with PhantomJS makes PhantomJS to crash.
# And if tests are run with Firefox, it needs UI
# Command to Run tests with PhantomJS (default): "npm test"
# Command to Run tests with Firefox: "firefox test/index.html"
