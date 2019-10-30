# ----------------------------------------------------------------------------
#
# Package       : eventemitter3
# Version       : 4.0.0
# Source repo   : https://github.com/primus/eventemitter3.git
# Tested on     : rhel 7.6
# Script License: Apache License, Version 2 or later
# Maintainer    : Dipika Joshi <dipika.joshi@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

yum update -y
yum install -y git curl

# NPM insatllation
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 
nvm install v8.9.4
ln -s $HOME/.nvm/versions/node/v8.9.4/bin/node /usr/bin/node
ln -s $HOME/.nvm/versions/node/v8.9.4/bin/npm /usr/bin/npm

npm install -g npm

git clone https://github.com/primus/eventemitter3.git
cd eventemitter3
sed -i -e 's/"mocha": "~6.2.0"/"mocha": ">=6.2.2"/g' package.json
sed -i -e 's/"pre-commit": "~1.2.0"/"pre-commit": ">=1.2.2"/g' package.json
sed -i -e 's/"uglify-js": "~3.6.0"/"uglify-js": ">=3.6.5"/g' package.json
sed -i -e 's/"nyc": "~14.1.0"/"nyc": ">=14.1.1"/g' package.json
sed -i -e 's/ "browserify": "~16.5.0",//g' package.json
sed -i -e 's/~/>=/g' package.json
sed -i -e 's/"devDependencies": {/"devDependencies": { "string.prototype.padstart": ">=3.0.0",/g' package.json

npm install -f
npm audit fix
npm install
npm test