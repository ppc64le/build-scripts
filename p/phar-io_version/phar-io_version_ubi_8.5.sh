#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : phar-io/version
# Version       : 1.0.1, 3.0.1, 3.1.0
# Source repo   : https://github.com/phar-io/version
# Tested on     : UBI 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : vathsala . <vaths367@in.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=version
PACKAGE_URL=https://github.com/phar-io/version
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-3.1.0}

yum module enable php:7.3 -y
yum install php php-json php-devel php-dom php-mbstring zip unzip php-zip wget git java-11-openjdk-devel -y
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
composer require --dev phpunit/phpunit --with-all-dependencies ^7

#Install ant
wget https://downloads.apache.org/ant/binaries/apache-ant-1.10.12-bin.tar.gz
tar -xf apache-ant-1.10.12-bin.tar.gz
# Set ANT_HOME variable
export ANT_HOME=${pwd}/apache-ant-1.10.12
# update the path env. variable
export PATH=${PATH}:${ANT_HOME}/bin

HOME_DIR=`pwd`

wget -O phive "https://phar.io/releases/phive.phar" && chmod +x phive && ./phive install

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi
cd "$HOME_DIR"/$PACKAGE_NAME || exit
git checkout "$PACKAGE_VERSION"

if [ $PACKAGE_VERSION == 3.1.0 ] ; then
        mkdir -p "$HOME/bin"
        export PATH="$HOME/bin:$PATH"
        if [ -n "$GITHUB_AUTH_TOKEN" ]; then echo "Github auth token found."; fi
        if [ ! -d "$HOME/.phive" ]; then mkdir "$HOME/.phive"; fi
        if [ ! -f "$HOME/.phive/phive.phar" ]; then ant getphive; mv phive.phar "$HOME/.phive/"; fi
        install --mode=0755 -T "$HOME/.phive/phive.phar" "$HOME/bin/phive"

elif [ $PACKAGE_VERSION == 3.0.1 ] || [ $PACKAGE_VERSION == 1.0.1 ] ; then
        wget "https://phar.io/releases/phive.phar"
        chmod +x phive.phar && ./phive.phar install
        mv phive.phar /usr/local/bin/phive
else
        echo "add your version to check any condition"
fi

if ! ant setup; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit
if ! ./tools/phpunit; then
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

#Both build and test passing for v3.0.1 and 3.1.0, and v1.0.1 is quite older and test is failing with deprication error
#PHP Fatal error:  Declaration of SebastianBergmann\Comparator\DOMNodeComparator::assertEquals($expected, $actual, $delta = 0, $canonicalize = false, $ignoreCase = false) must be 
#compatible with SebastianBergmann\Comparator\ObjectComparator::assertEquals($expected, $actual, $delta = 0, $canonicalize = false, $ignoreCase = false, array &$processed = Array) 
#in phar:///root/.phive/phars/phpunit-5.7.5.phar/sebastian-comparator/DOMNodeComparator.php on line 110
