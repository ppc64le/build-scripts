#!/bin/bash
# ----------------------------------------------------------------------------
#
# Package       : logstash
# Version       : v8.3.3
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

PACKAGE_NAME=logstash
PACKAGE_VERSION=${1:-v8.3.3}
PACKAGE_URL=https://github.com/elastic/logstash.git


# installing dependencies
yum update -y && yum install -y git make unzip tar ruby gcc-c++  wget gzip procps shadow-utils zip which sudo yum-utils java-11-openjdk-devel

export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk/
export PATH=$PATH:/usr/lib/jvm/java-11-openjdk/bin

sudo ln -sf /usr/lib/jvm/java-11-openjdk/bin/java /usr/bin/

yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/
yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/
yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official


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
git checkout $PACKAGE_VERSION
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/l/logstash/logstash_patchfile.patch
git apply logstash_patchfile.patch 
sed -i '2d' ./rakelib/artifacts.rake
rake bootstrap
if ! rake plugin:install-default; then
    echo "Build fails"
    exit 1
fi

if ! ./gradlew test; then
    echo "Test fails"
    exit 2
else
    echo "Build and test successful"
    exit 0
fi