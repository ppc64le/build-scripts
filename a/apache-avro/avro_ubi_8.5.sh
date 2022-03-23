#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : apache-avro
# Version       : 1.10.1
# Source repo   : https://github.com/apache/avro
# Tested on     : UBI 8.5
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Raju Sah <Raju.Sah@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=avro
PACKAGE_VERSION=${1:-1.10.1}
PACKAGE_URL=https://github.com/apache/avro.git

# install dependencies
yum install -y git curl java-1.8.0-openjdk make maven gcc cmake ruby ruby-devel redhat-rpm-config

#install Forrest
mkdir -p /usr/local/apache-forrest
curl -O http://archive.apache.org/dist/forrest/0.8/apache-forrest-0.8.tar.gz
tar xzf *forrest* --strip-components 1 -C /usr/local/apache-forrest
echo 'forrest.home=/usr/local/apache-forrest' > build.properties
chmod -R 0777 /usr/local/apache-forrest/build /usr/local/apache-forrest/main /usr/local/apache-forrest/plugins
export FORREST_HOME=/usr/local/apache-forrest


# Install Perl modules
curl -L https://cpanmin.us | perl - App::cpanminus
cpanm install Module::Install Module::Install::ReadmeFromPod \
Module::Install::Repository \
Math::BigInt JSON::XS Try::Tiny Regexp::Common Encode \
IO::String Object::Tiny Compress::Zlib Test::More \
Test::Exception Test::Pod

# Install Ruby modules
gem install echoe yajl-ruby multi_json snappy bundle

# Install global Node modules
curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh -o install_nvm.sh
sh install_nvm.sh
source /root/.nvm/nvm.sh
nvm install 8.14.0
npm install -g grunt-cli

# Install AVRO
git clone $PACKAGE_URL
cd  $PACKAGE_NAME/ && git checkout release-$PACKAGE_VERSION
mvn clean install -DskipTests
mvn test
