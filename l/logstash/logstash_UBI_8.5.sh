#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : logstash
# Version       : 8.4.0,8,4.1
# Source repo   : https://github.com/elastic/logstash.git
# Tested on     : UBI 8.5
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


WORKDIR=$1
cd $WORKDIR

# installing dependencies
yum update -y && yum install -y git make unzip tar ruby gcc-c++  wget gzip procps shadow-utils zip which

wget https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.1%2B10/OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz
tar -C /usr/local -xzf OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"
export JAVA_HOME=/usr/local/jdk-18.0.1+10/
export PATH=$PATH:/usr/local/jdk-18.0.1+10/bin
sudo ln -sf /usr/local/jdk-18.0.1+10/bin/java /usr/bin/
rm -f OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz


# Install latest version of Ruby using rvm
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -sSL https://get.rvm.io | bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
gem install rake 
gem install bundler

rvm install "jruby-9.3.4.0"

# install logstash
cd $WORKDIR
git clone https://github.com/elastic/logstash.git
cd logstash
git checkout v8.4.1
sed -i '2d' ./rakelib/artifacts.rake
rake bootstrap
rake plugin:install-default

git apply logstash_patch.patch 

./gradlew test

