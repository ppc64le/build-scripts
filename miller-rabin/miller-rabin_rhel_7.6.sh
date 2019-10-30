# ----------------------------------------------------------------------------
#
# Package       : miller-rabin
# Version       : 4.0.1
# Source repo   : https://github.com/indutny/miller-rabin.git
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
yum install -y libX11-devel firefox xorg-x11-server-Xvfb glibc-devel git curl dbus-x11

# NPM insatllation
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 
nvm install v8.9.4
ln -s $HOME/.nvm/versions/node/v8.9.4/bin/node /usr/bin/node
ln -s $HOME/.nvm/versions/node/v8.9.4/bin/npm /usr/bin/npm

git clone https://github.com/indutny/miller-rabin.git
cd miller-rabin
sed -i -e 's/"mocha": "^2.0.1"/"mocha": "6.2.2"/g' package.json
sed -i -e '8s/$/,/' package.json
a=`awk '/"test":/{print NR}' package.json`
mv package.json package1.json
head -n $a ./package1.json > package.json
echo "\"test\": \"mocha --timeout 10000\"" >> package.json
b=`expr "$a" + 1 `
tail -n +$b ./package1.json >> package.json
rm package1.json

npm install
npm test