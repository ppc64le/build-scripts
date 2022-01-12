#! /bin/bash
# -----------------------------------------------------------------------------
#
# Package       : twig/twig
# Version       : 1.42.4, 1.42.5 
# Source repo   : https://github.com/twigphp/Twig
# Tested on     : rhel 8.4
# Maintainer    : Nailusha Potnuru <pnailush@in.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=twig
PACKAGE_VERSION=${1:-1.42.5}
PACKAGE_URL=https://github.com/twigphp/Twig.git
yum -y update && yum install -y git curl php php-curl php-json php-dom php-mbstring make unzip 
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
if ! composer install; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 0
else
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Install_Successful"
fi
cd $HOME_DIR/$PACKAGE_NAME
if ! $HOME_DIR/vendor/bin/phpunit; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        echo "This package require to be test in non-root mode to pass all test"
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi
