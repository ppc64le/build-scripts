#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: jekyll-seo-tag
# Version	: v2.4.0
# Source repo	: https://github.com/jekyll/jekyll-seo-tag
# Tested on	: UBI: 8.5
# Language      : Ruby
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Vishaka Desai <Vishaka.Desai@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jekyll-seo-tag
PACKAGE_VERSION=${1:-v2.4.0}
PACKAGE_URL=https://github.com/jekyll/jekyll-seo-tag

yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2 ruby libcurl-devel libffi-devel ruby-devel redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel rubygem-rake
yum install -y --allowerasing yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget

yum-config-manager --add-repo https://ftp.plusline.net/centos/8-stream/AppStream/ppc64le/os/ 
yum-config-manager --add-repo https://ftp.plusline.net/centos/8-stream/PowerTools/ppc64le/os/ 
yum-config-manager --add-repo https://ftp.plusline.net/centos/8-stream/BaseOS/ppc64le/os/ 
yum-config-manager --add-repo https://ftp.plusline.net/centos/8-stream/virt/ppc64le/ovirt-44/

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Virtualization 
mv RPM-GPG-KEY-CentOS-SIG-Virtualization /etc/pki/rpm-gpg/. 
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official 
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. 
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y libsodium-devel libicu-devel libicu langtable

gem install bundle
gem install bundler:1.17.3
gem install rake
gem install kramdown-parser-gfm
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable --auto-dotfiles
usermod -aG rvm root
source /etc/profile.d/rvm.sh 
rvm reload
rvm install ruby-2.7

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

#install previous version of bundler
gem install bundler:1.17.3
gem install kramdown-parser-gfm

function test_with_ruby(){
	echo "Automation via Ruby version 2.7"
	if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
		echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
		exit 1
	fi

	cd $PACKAGE_NAME
	git checkout $PACKAGE_VERSION
	
	# some packages have checksum corrupted, hence disabling checksum
	bundle config set --local disable_checksum_validation true
	if ! bundle _1.17.3_  install; then
		if ! bundle install; then
			exit 1;
		fi
	fi
	bundle config set --local disable_checksum_validation false

	if test -f ".rspec"; then
		if ! bundle _1.17.3_ exec rspec; then
			if ! bundle exec rspec; then
				echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
				echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
				echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
				exit 1
			fi
		else
			echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
			exit 0
		fi
	else
		echo "------------------$PACKAGE_NAME:install_success_&_test_NA-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success_and_Test_NA" > /home/tester/output/version_tracker
		exit 0
	fi
}

test_with_ruby