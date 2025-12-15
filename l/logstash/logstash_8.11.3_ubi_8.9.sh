#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: elastic/logstash
# Version	: v8.11.3
# Source repo	: https://github.com/elastic/logstash
# Tested on	: UBI8.7, UBI_8.9
# Language      : JAVA/Ruby
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=elastic/logstash
PACKAGE_VERSION=${1:-v8.11.3}
PACKAGE_URL=https://github.com/elastic/logstash

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
JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.21.0.9-2.el8.ppc64le/
export PATH=/usr/lib/jvm/java-11-openjdk-11.0.21.0.9-2.el8.ppc64le/bin:$PATH

# Clone repo and checkout to required version
git clone https://github.com/elastic/logstash
cd logstash
git checkout $PACKAGE_VERSION

#install rvm and ruby (ruby version should be same as in .ruby_version in logstash
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable --ruby=$(cat .ruby-version)
source /etc/profile.d/rvm.sh

#print rvm and ruby versions
rvm --version
ruby --version
#echo "install ruby using rvm"
#rvm install ruby

#echo "install jruby   "
#rvm install jruby

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

rake --version

bundle -v

#build and install using gradle
export OSS=true
export LOGSTASH_SOURCE=1
export LOGSTASH_PATH=/logstash
if ! ./gradlew installDevelopmentGems; then 
 echo "failed to build/install development dependencies"
 exit 1
else
 echo "Successfully completed  build/install development dependencies"
fi

if ! ./gradlew installDefaultGems; then 
 echo "failed to build/install default plugins and other dependencies"
 exit 1
else
 echo "Successfully completed build/install default plugins and other dependencies"
fi

#run tests
export LS_HEAP_SIZE=2048m

# run the core tests
if ! ./gradlew test; then
	echo "Core test failed"
	exit 2
else
	echo "Successfully completed core test"
fi

# execute the complete test-suite including the integration tests run
if ! ./gradlew check; then
	echo "Integration test failed"
	exit 2
else
	echo "Successfully completed Integration test"
fi

# run the tests of all currently installed plugins (i.e. default plugins)
#if ! rake test:plugins; then
#	echo "Default plugin tests failed"
#	exit 1
#else
#	echo "Plugin tests completed successfully"
#fi

exit 0






