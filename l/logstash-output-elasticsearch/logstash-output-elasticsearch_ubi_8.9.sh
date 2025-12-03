#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package	: logstash-output-elasticsearch
# Version	: v11.22.2
# Source repo	: https://github.com/logstash-plugins/logstash-output-elasticsearch
# Tested on	: UBI_8.9
# Language      : JAVA/Ruby
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Ashutosh Jadhav <Ashutosh.Jadhav2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=logstash-output-elasticsearch
PACKAGE_VERSION=${1:-v11.22.2}
PACKAGE_URL=https://github.com/logstash-plugins/logstash-output-elasticsearch

LOGSTASH_PACKAGE_NAME=logstash
LOGSTASH_PACKAGE_VERSION=${1:-v8.11.3}
LOGSTASH_PACKAGE_URL=https://github.com/elastic/logstash

OS_VERSION=$(grep ^VERSION_ID /etc/os-release | cut -d= -f2 | cut -d\" -f2)
echo "RHEL VERSION is $OS_VERSION"

yum -y update && yum install -y git procps yum-utils wget ncurses make gcc-c++ libffi-devel java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless

# Adding repo to install bison and readline
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/
yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

#Install bison and readline-devel
yum install -y bison readline-devel

#set JAVA_HOME and path
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-17.0.10.0.7-2.el8.ppc64le/
export PATH=$JAVA_HOME:$PATH

# We need to build logstash to build logstash-output-elasticsearch
# Clone repo and checkout to required version for logstash
git clone $LOGSTASH_PACKAGE_URL
cd $LOGSTASH_PACKAGE_NAME
git checkout $LOGSTASH_PACKAGE_VERSION

#install rvm and ruby (ruby version should be same as in .ruby_version in logstash
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable --ruby=$(cat .ruby-version)
source /etc/profile.d/rvm.sh

# install rake and bundler using gem
if [[ "$OS_VERSION" == "8.7" ]]
 then
  # On ubi8.7 older version of rake is required.
  # To fix CI pipeline failure added this.
  echo "Installing rake version 13.0.6"
  gem install rake --version 13.0.6
else
  echo "Installing rake latest version"
  gem install rake
fi

gem install bundler

#build and install the logstash using gradle
export OSS=true
export LOGSTASH_SOURCE=1
export LOGSTASH_PATH=/logstash
if ! ./gradlew installDevelopmentGems; then 
 echo "Logstash failed to build/install development dependencies"
 exit 1
else
 echo "Logstash successfully completed  build/install development dependencies"
fi

# Clone repo and checkout to required version for logstash-output-elasticsearch
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Updating the dependency for logstash-output-elasticsearch
bundle update 

if ! bundle install; then
  echo "Ruby dependency installation failed"
  exit 1
fi

# execute the complete test-suite of logstash-output-elasticsearch including integration tests run
if ! bundle exec rspec --format=documentation spec/unit --tag ~integration --tag ~secure_integration; then
  echo "Build and Test failed"
  exit 2
else
  echo "Build and Test successful..... "
fi

exit 0
