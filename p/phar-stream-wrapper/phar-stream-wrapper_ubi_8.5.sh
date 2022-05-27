# -----------------------------------------------------------------------------
#
# Package	: phar-stream-wrapper
# Version	: v3.1.5
# Source repo	: https://github.com/TYPO3/phar-stream-wrapper.git
# Tested on	: ubi 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="phar-stream-wrapper"
PACKAGE_URL="https://github.com/TYPO3/phar-stream-wrapper.git"
PACKAGE_VERSION=${1:-"v3.1.5"}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

dnf install -y git curl php php-dom php-mbstring php-json php-gd php-pecl-zip php-pdo xz zip php php-devel php-pear make
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

pecl install xdebug
tee /etc/php.d/30-xdebug.ini >/dev/null <<-config
    zend_extension="/usr/lib64/php/modules/xdebug.so"
    xdebug.remote_log="/tmp/xdebug.log"
    xdebug.profiler_enable = 1
    xdebug.remote_enable=on
    xdebug.remote_port=9000
    xdebug.remote_autostart=0
    xdebug.remote_connect_back=on
    xdebug.idekey=editor-xdebug
config

HOME_DIR=$(pwd)
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
git checkout "$PACKAGE_VERSION" || exit 1
composer require --dev phpunit/phpunit --with-all-dependencies ^7
if ! composer install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
if ! ./vendor/bin/phpunit; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
