#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : 3scale/toolbox
# Version       : 2.13.0
# Source repo   : https://github.com/3scale/3scale_toolbox.git
# Tested on     : ubuntu:20.04
# Language      : Ruby
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ujwal Akare <Ujwal.Akare@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------


PACKAGE_NAME=3scale_toolbox
PACKAGE_VERSION=${1:-v2.13.0}
PACKAGE_BRANCH=3scale-2.13-stable
PACKAGE_URL=https://github.com/3scale/3scale_toolbox.git

# clone branch/release passed as argument, if none, use last stable release

#Download Updates and Dependencies
apt-get update

#install git
apt install -y git 

#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"
fi

if ! git clone $PACKAGE_URL -b $PACKAGE_BRANCH ; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

echo "BRANCH_NAME = $PACKAGE_BRANCH"

cd $PACKAGE_NAME

#Install required prerequisites
#Install Ruby Using Rbenv

#Download and install the libraries and compilers Ruby needs to run
apt install curl autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev 

#Download and run the shell script used to install Rbenv:
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

#need to add $HOME/.rbenv/bin to our PATH environment variable to start using Rbenv for bash shell.


echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"

#ruby install using rbenv
rbenv install 2.7.2

#Set the newly installed version of Ruby as the global version:
rbenv global 2.7.2

export PATH="$HOME/.rbenv/shims:$PATH"

#install 3scale/3scale_toolbox
gem install 3scale_toolbox
gem install rails
bundle install
gem install racc

# Rake install

bundle exec rake install

# Running Unit Test

	if ! bundle exec rake spec:unit; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
		exit 1
	else	
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME"
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
	fi	
	
	# Trigger Integration Tests
	#bundle exec rake spec:integration
	
	#When we try to create a service. The tenant (admin account) does not have permissions to add more services. 
	#The integration tests create services and then delete them when done. 
	#We can't create new services manually from the dashboard, Since to run Integration test we require paid account on 3scale to create multiple tenant, So we can't run test the Integration test.


# cleanup
cd ..
rm -rf 3scale_toolbox





