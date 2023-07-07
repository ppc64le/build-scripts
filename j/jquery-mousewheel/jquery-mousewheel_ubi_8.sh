#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package		: jquery-mousewheel
# Version		: 3.1.11
# Source repo		: https://github.com/jquery/jquery-mousewheel.git
# Tested on		: UBI 8.4
# Language     		: Node
# Travis-Check	 	: True
# Script License	: Apache License, Version 2 or later
# Maintainer		: Vaishnavi Patil <Vaishnavi.Patil3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jquery-mousewheel
PACKAGE_VERSION=${1:-3.1.11}
PACKAGE_URL=https://github.com/jquery/jquery-mousewheel.git


yum install git npm zip unzip wget -y

# ----------------------------------------------------------------------------
# Prerequisites:
#
# chrome must be installed. Following are the steps to install chrome. Uncomment the following lines to install chrome
# ----------------------------------------------------------------------------
#set +ex
#echo -n "Please enter your IBM W3 Username: "
#read W3_USERNAME
#echo -n "Please enter your W3 Password:"
#read -s W3_PASSWORD
#set -ex
#set +ex
#wget --user $W3_USERNAME --password $W3_PASSWORD https://na.artifactory.swg-devops.com/artifactory/wiotp-generic-local/ppc/dependencies/chrome/chrome.ppc64le.tgz
#set -ex
#tar -xzvf chrome.ppc64le.tgz

mkdir -p /home/tester/output
cd /home/tester

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL ; then
    	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
    	exit 0
fi

cd /home/tester/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! npm install && npm audit fix && npm audit fix --force; then
     	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
	exit 1
fi
npm build

if [ $PACKAGE_VERSION = main ]; then
	dnf -y install https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-3.el8.noarch.rpm https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-3.el8.noarch.rpm
	sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Linux-*
	sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Linux-*
	yum install -y firefox libXScrnSaver libdrm mesa-libgbm alsa-lib libxshmfence
	export FIREFOX_BIN=/usr/bin/firefox
#	uncomment below 2 lines to set CHROME_BIN
#	export CHROME_BIN=/chromium/chrome
#	chmod 777 $CHROME_BIN
	cd /home/tester/$PACKAGE_NAME
	sed -i "s#'--headless'#'--headless', '--no-sandbox'#g" ./node_modules/karma-chrome-launcher/index.js
	sed -i 's#"Chrome", "Firefox"#"ChromeHeadless", "FirefoxHeadless"#g' test/karma.conf.js

	cd /home/tester/$PACKAGE_NAME
	if ! npm run karma; then
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
	exit 1
else
	echo "For version other that main version there are no unit tests. Manual tests needs to be run"
	exit 0
fi
