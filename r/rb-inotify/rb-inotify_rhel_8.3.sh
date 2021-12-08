# -----------------------------------------------------------------------------
#
# Package	: rb-inotify
# Version	: 0.9.10
# Source repo	: https://github.com/guard/rb-inotify
# Tested on	: RHEL 8.3
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=rb-inotify
PACKAGE_VERSION=0.9.10
PACKAGE_URL=https://github.com/guard/rb-inotify

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2
yum install ruby -y && yum install -y libcurl-devel libffi-devel ruby-devel ruby-devel.ppc64le redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel
gem install bundle && gem install bundler:1.17.3 && gem install rake
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm install jruby
export PATH=$PATH:/usr/local/rvm/rubies/jruby-9.2.9.0/bin/

source /etc/profile.d/rvm.sh;
OS_NAME=`python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])"`

#install previous version of bundler
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
