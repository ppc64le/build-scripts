#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package		: path_expander
# Version		: v1.1.1
# Source repo	: https://github.com/seattlerb/path_expander
# Tested on		: UBI 9.3
# Language      : Ruby
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=path_expander
PACKAGE_VERSION=${1:-v1.1.1}
PACKAGE_URL=https://github.com/seattlerb/path_expander.git

yum install -y git wget curl ruby ruby-devel rubygem-rake procps libcurl-devel libffi-devel --allowerasing

gem install bundle
gem install rake
gem install kramdown-parser-gfm


mkdir -p /home/tester/output
cd /home/tester


git clone $PACKAGE_URL 
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

gem install hoe
gem install minitest


if ! rake package; then
	echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
	exit 1
fi

if ! rake test; then
	echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
	exit 2
else
	echo "------------------$PACKAGE_NAME:Build_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Build_and_Test_Success"
	exit 0
fi
