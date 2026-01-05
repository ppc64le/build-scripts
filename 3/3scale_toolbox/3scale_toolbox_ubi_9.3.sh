#!/bin/bash
# ---------------------------------------------------------------------
#
# Package       : 3scale_toolbox
# Version       : 3scale-2.15.1-GA
# Source repo   : https://github.com/3scale/3scale_toolbox
# Tested on     : UBI:9.3
# Language      : Ruby
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Gupta <Shubham.Gupta43@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------

PACKAGE_NAME=3scale_toolbox
PACKAGE_VERSION=${1:-3scale-2.15.1-GA}
PACKAGE_URL=https://github.com/3scale/3scale_toolbox

#install git and wget
yum install -y git wget gcc gcc-c++ make automake autoconf curl-devel openssl-devel zlib-devel httpd-devel apr-devel apr-util-devel sqlite-devel perl-FindBin

git clone $PACKAGE_URL -b $PACKAGE_VERSION
echo "BRANCH_NAME = $PACKAGE_VERSION"
cd $PACKAGE_NAME

#To enable yum-config-manager
yum install -y yum-utils

#Adding repo to install flex, bison and readline
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
curl -o /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y flex flex-devel bison readline-devel

#Install Ruby Using Rbenv
#Download and run the shell script used to install Rbenv:
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

#need to add $HOME/.rbenv/bin to our PATH environment variable to start using Rbenv for bash shell.
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"

#ruby install using rbenv
rbenv install 3.0.0

#Set the newly installed version of Ruby as the global version:
rbenv global 3.0.0
export PATH="$HOME/.rbenv/shims:$PATH"

# Install nokogiri
yum install -y libxml2
yum install -y zlib-devel xz patch
gem install nokogiri --platform=ruby

#install 3scale/3scale_toolbox
gem install 3scale_toolbox
gem install rails
bundle install
gem install racc

# Rake install
if ! bundle exec rake install; then
	echo "------------------$PACKAGE_NAME:Install_Failure---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Failure"
	exit 1
fi

# Running Unit Test
if ! bundle exec rake spec:unit; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
