# -----------------------------------------------------------------------------
#
# Package	: {package_name}
# Version	: {package_version}
# Source repo	: {package_url}
# Tested on	: {distro_name} {distro_version}
# Language      : Ruby
# Travis-Check  : True
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

PACKAGE_NAME=${PACKAGE_NAME}
PACKAGE_VERSION=${PACKAGE_VERSION}
PACKAGE_URL=${PACKAGE_URL}

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2 ruby libcurl-devel libffi-devel ruby-devel redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel rubygem-rake

# gcc dev tools
#  yum groupinstall 'Development Tools' -y
# as development group is not available in UBI 8 container
# adding individual packages manually from the group
yum install -y --allowerasing gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget

yum-config-manager --add-repo http://mirror.centos.org/centos/8/AppStream/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/PowerTools/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/virt/ppc64le/ovirt-44/

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-Virtualization && mv RPM-GPG-KEY-CentOS-SIG-Virtualization /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization

yum install -y libsodium-devel libicu-devel libicu langtable

gem install bundle
gem install bundler:1.17.3
gem install rake
gem install kramdown-parser-gfm
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable
/bin/bash -c "source /etc/profile.d/rvm.sh; rvm install ruby-2.7;"

mkdir -p /home/tester/output
cd /home/tester

export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

source /etc/profile.d/rvm.sh;
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# Jruby is needed only by few packages like logstash, hence differing setting in PATH till needed

#install previous version of bundler
gem install bundler:1.17.3
gem install kramdown-parser-gfm

function test_with_jruby(){
	echo "Automation using Jruby"
	rvm install jruby
	export PATH=/usr/local/rvm/rubies/jruby-9.2.9.0/bin/:$PATH
	if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
			echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
			echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
			exit 1
	fi

	cd /home/tester/$PACKAGE_NAME
	git checkout $PACKAGE_VERSION
	if ! bundle install; then
			echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
		exit 1
	fi
	bundle config set --local disable_checksum_validation false
	cd /home/tester/$PACKAGE_NAME
	#- Check if script/cibuild file exists, if exists, run the script
	#- else check if .rspec exists, if yes run bundle exec rspec
	#- else check if Rakefile exists, run bundle exec rake
	#- else mark as no tests available
	if test -f "script/cibuild"; then
		chmod u+x script/cibuild
		if ! script/cibuild; then
			echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
			exit 1
		else
			echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
			exit 0
		fi
	elif test -f ".rspec"; then
		if ! bundle exec rspec; then
				echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
				echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
				echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
				exit 1
		else
			echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
			exit 0
		fi
	elif test -f "Rakefile"; then
		if ! bundle exec rake; then
			echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
			exit 1
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

function test_with_ruby(){
	echo "Automation via Ruby version 2.7"
	if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
		echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
		exit 1
	fi

	cd /home/tester/$PACKAGE_NAME
	git checkout $PACKAGE_VERSION
	# some packages have checksum corrupted, hence disabling checksum
	bundle config set --local disable_checksum_validation true
	if ! bundle _1.17.3_  install; then
		if ! bundle install; then
			test_with_jruby
		fi
	fi
	bundle config set --local disable_checksum_validation false

	cd /home/tester/$PACKAGE_NAME
	#- Check if script/cibuild file exists, if exists, run the script
	#- else check if .rspec exists, if yes run bundle exec rspec
	#- else check if Rakefile exists, run bundle exec rake
	#- else mark as no tests available
	if test -f "script/cibuild"; then
		chmod u+x script/cibuild
		if ! script/cibuild; then
			echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
			exit 1
		else
			echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
			exit 0
		fi
	elif test -f ".rspec"; then
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
	elif test -f "Rakefile"; then
		if ! bundle _1.17.3_ exec rake; then
			if ! bundle exec rake; then
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

# Try building packages with normal ruby compiler as its needed to build native packages, if it does not work fallback to jruby compiler
test_with_ruby
