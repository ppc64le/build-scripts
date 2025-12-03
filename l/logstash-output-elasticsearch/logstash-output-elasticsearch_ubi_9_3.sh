#!/bin/bash 
# -----------------------------------------------------------------------------
#
# Package	        : logstash-output-elasticsearch
# Version	        : v11.22.7
# Source repo	    : https://github.com/logstash-plugins/logstash-output-elasticsearch
# Tested on	        : UBI: 9.3
# Language          : Ruby
# Ci-Check      : True
# Script License    : Apache License, Version 2 or later
# Maintainer	    : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=logstash-output-elasticsearch
PACKAGE_VERSION=${1:-v11.22.7}
PACKAGE_URL=https://github.com/logstash-plugins/logstash-output-elasticsearch
HOME_DIR=${PWD}

#install dependencies
yum install -y git procps yum-utils wget ncurses make gcc-c++ libffi-devel java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless

# Adding repo to install bison and readline
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/

wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

#Install bison and readline-devel
yum install -y bison readline-devel

#set JAVA_HOME and path
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)')
export PATH=$JAVA_HOME:$PATH

# We need to build logstash to build logstash-output-elasticsearch
# Clone repo and checkout to required version for logstash
cd $HOME_DIR
git clone https://github.com/elastic/logstash
cd logstash
git checkout v8.14.1

#install rvm and ruby (ruby version should be same as in .ruby_version in logstash
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable --ruby=$(cat .ruby-version) 2>&1 | grep -v "Unknown ruby string" || true
source /etc/profile.d/rvm.sh

echo "Installing rake latest version"
gem install rake
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
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Build package
if !(bundle install); then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if !(bundle exec rspec --format=documentation spec/unit); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi

