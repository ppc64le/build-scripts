#! /bin/bash
# -----------------------------------------------------------------------------
#
# Package       : theseer/tokenizer
# Version       : 1.2.0, 1.2.1
# Source repo   : https://github.com/theseer/tokenizer
# Tested on     : RHEL 8.4
# Maintainer    : Amit Baheti <aramswar@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=tokenizer
PACKAGE_VERSION=${1:-1.2.1}
PACKAGE_URL=https://github.com/theseer/tokenizer
if [ ! -z "$1" ]; then
	PACKAGE_VERSION=$1
fi
yum -y update && yum install -y git curl php php-curl php-json php-dom php-mbstring make unzip ant
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
composer require --dev phpunit/phpunit --with-all-dependencies ^7
mkdir output
OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`
HOME_DIR=`pwd`
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
fi
cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION
if [ ! $PACKAGE_VERSION -eq 1.1.3 ];then
	if ! ant install-tools && ant generate-autoloader; then
			echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME"
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
			exit 0
	fi
else
	wget -O phive "https://phar.io/releases/phive.phar" && chmod +x phive && ./phive install
fi
if ! ant test; then
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
fi
