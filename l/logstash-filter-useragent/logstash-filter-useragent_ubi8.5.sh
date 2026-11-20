#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : logstash-filter-useragent
# Version       : v3.1.1
# Source repo   : https://github.com/logstash-plugins/logstash-filter-useragent.git
# Language		: Ruby
# Tested on     : UBI: 8.5
# Travis-Check  : True
# Script License: Apache License Version 2.0
# Maintainer    : Eshant Gupta <eshant.gupta1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=logstash-filter-useragent
PACKAGE_VERSION=${1:-v3.1.1}
PACKAGE_URL=https://github.com/logstash-plugins/logstash-filter-useragent.git

if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
 
fi

yum install -y procps git curl jq gnupg2 ruby libcurl-devel libffi-devel ruby-devel ruby-devel.ppc64le redhat-rpm-config java-1.8.0-openjdk-devel ncurses gcc-c++ make python3

# Installing dependencies
gem install bundle
gem install bundler:1.17.3
gem install rake
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
source /usr/local/rvm/scripts/rvm


rvm install "jruby-9.1.12.0"
export PATH=$PATH:/usr/local/rvm/rubies/jruby-9.1.12.0/bin/

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
gem install bundler:1.17.3
HOME_DIR=`pwd`


if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    	exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! bundle _1.17.3_  install; then
	if ! bundle install; then
     		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
		exit 0
	fi
fi

cd $HOME_DIR/$PACKAGE_NAME
if ! bundle _1.17.3_ exec rake; then
	if ! bundle exec rake; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
		exit 0
	fi
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
