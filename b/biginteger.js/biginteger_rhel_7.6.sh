# ----------------------------------------------------------------------------
#
# Package       : BigInteger.js
# Version       : v1.6.40
# Source repo   : https://github.com/peterolson/BigInteger.js.git
# Tested on     : rhel 7.6
# Travis-Check  : False
# Script License: Apache License Version 2.0
# Maintainer    : Lysanne Fernandes <lysannef@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

if [ "$#" -gt 0 ]
then
    VERSION=$1
else
    VERSION="1.6.40"
fi

yum update -y
yum install -y libX11-devel firefox xorg-x11-server-Xvfb glibc-devel git

# Setup Firefox
export DISPLAY=:99
Xvfb :99 -screen 0 640x480x8 -nolisten tcp &
dbus-uuidgen > /var/lib/dbus/machine-id

# Install nodejs
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install v8.9.4
ln -s $HOME/.nvm/versions/node/v8.9.4/bin/node /usr/bin/node
ln -s $HOME/.nvm/versions/node/v8.9.4/bin/npm /usr/bin/npm

cd $HOME
git clone https://github.com/peterolson/BigInteger.js.git
cd BigInteger.js
git checkout v$VERSION
sed -i 's/karma-phantomjs-launcher": "^1.0.4/karma-firefox-launcher": "^1.2.0/g' package.json
sed -i 's/PhantomJS/Firefox/g' my.conf.js
npm install

# Uncomment the following lines to execute tests
#npm test
