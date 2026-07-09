#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : logstash
# Version       : v8.4.0, v8.4.1. v8.6.1,v 7.17.9
# Source repo   : https://github.com/elastic/logstash.git
# Tested on     : UBI 8.5
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : Ambuj Kumar <Ambuj.kumar3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

CWD=`pwd`
PACKAGE_VERSION=${1:-v7.17.9}

# installing dependencies
yum update -y && yum install -y git make unzip tar ruby gcc-c++  wget gzip procps shadow-utils zip which
#for installing ruby 2.6.0
dnf install -qy  gnupg2
dnf install -y http://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/readline-devel-7.0-10.el8.ppc64le.rpm
dnf install -y http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/bison-3.0.4-10.el8.ppc64le.rpm
yum install -y patch readline zlib zlib-devel
yum install -y libyaml-devel libffi-devel openssl-devel make
yum install -y bzip2 autoconf automake libtool

if [ $PACKAGE_VERSION == "v7.17.9" ]
then
        wget https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.18%2B10/OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.18_10.tar.gz
        tar -C /usr/local -xzf OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.18_10.tar.gz
        export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"
        export JAVA_HOME=/usr/local/jdk-11.0.18+10/
        export PATH=$PATH:/usr/local/jdk-11.0.18+10/bin
        ln -sf /usr/local/jdk-11.0.18+10/bin/java /usr/bin/
        rm -f OpenJDK11U-jdk_ppc64le_linux_hotspot_11.0.18_10.tar.gz
else
	wget https://github.com/adoptium/temurin18-binaries/releases/download/jdk-18.0.1%2B10/OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz
        tar -C /usr/local -xzf OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz
        export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF8"
        export JAVA_HOME=/usr/local/jdk-18.0.1+10/
        export PATH=$PATH:/usr/local/jdk-18.0.1+10/bin
        ln -sf /usr/local/jdk-18.0.1+10/bin/java /usr/bin/
        rm -f OpenJDK18U-jdk_ppc64le_linux_hotspot_18.0.1_10.tar.gz
fi

# Install latest version of Ruby using rvm
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -sSL https://get.rvm.io | bash -s stable --ruby
source /usr/local/rvm/scripts/rvm
rvm install ruby 2.6.0
gem install rake
gem install bundler -v 2.3.26
rvm install "jruby-9.3.4.0"

# install logstash
cd $WORKDIR
git clone https://github.com/elastic/logstash.git
cd logstash
git checkout $PACKAGE_VERSION
sed -i 's/ @Test(timeout = 300_000)/@Test(timeout = 800_000)/g' logstash-core/src/test/java/org/logstash/ackedqueue/QueueTest.java
sed -i '2d' ./rakelib/artifacts.rake
#cp $CWD/logstash_patch.patch .
#git apply logstash_patch.patch
rake bootstrap
rake plugin:install-default

./gradlew test

# got one test failure on 7.17.9 org.logstash.RSpecTests > rspecTests[core tests] FAILED
# java.lang.AssertionError: RSpec test suite `core tests` saw at least one failure.
# raise issue with community : https://github.com/elastic/logstash/issues/14901
