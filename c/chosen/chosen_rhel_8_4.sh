# -----------------------------------------------------------------------------
#
# Package       : chosen
# Version       : 1.0.0
# Source repo   : https://github.com/harvesthq/chosen/archive/1.0.0.zip
# Tested on     : UBI 8
# Script License: Apache License, Version 2 or later
# Maintainer    : sachin.kakatkar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#To Run: ./chosen_rhel_8_4.sh
dnf install git wget npm make gcc-c++ bzip2 unzip ruby -y
wget https://github.com/harvesthq/chosen/archive/1.0.0.zip
unzip 1.0.0.zip
mv chosen-1.0.0 chosen
cd chosen
npm install && gem install bundler && bundle install
npm audit fix
npm audit fix --force
npm install -g grunt-cli
npm install -g grunt
npm install --dev coffeescript
npm install && gem install bundler && bundle install
grunt build
grunt build --force
