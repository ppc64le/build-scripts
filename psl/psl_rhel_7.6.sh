# ----------------------------------------------------------------------------
#
# Package       : psl
# Version       : v1.6.0
# Source repo   : https://github.com/lupomontero/psl
# Tested on     : rhel 7.6
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
   PSL_VERSION=$1
else
    PSL_VERSION="1.6.0"
fi


yum update -y
yum install -y libX11-devel firefox xorg-x11-server-Xvfb glibc-devel git dbus-x11

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
git clone https://github.com/lupomontero/psl.git
cd psl
git checkout v$PSL_VERSION
sed -i -e 's/karma-phantomjs-launcher": "^1.0.4/karma-firefox-launcher": "^1.2.0/g' -e '/"phantomjs-prebuilt": "^2.1.16",/d' package.json
sed -i -e 's/PhantomJS/Firefox/g' -e 's/karma-phantomjs-launcher/karma-firefox-launcher/g' karma.conf.js
npm install

#Remove comments to execute test cases
#npm test

