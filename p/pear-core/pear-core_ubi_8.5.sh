#!/bin/bash -e

# ----------------------------------------------------------------------------
# Package          : pear-core
# Version          : v1.10.12
# Source repo      : https://github.com/pear/pear-core
# Tested on        : UBI 8.5
# Language         : PHP
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagat Singh <Bhagat.singh1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#   
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=pear-core
PACKAGE_URL=https://github.com/pear/pear-core
#PACKAGE_VERSION is configurable can be passed as an argument.
PACKAGE_VERSION=${1:-v1.10.12}

yum install -y git curl php php-curl php-dom php-mbstring php-json php-gd php-pecl-zip zlib-devel php-pear
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer


#Check if package exists
if [ -d "$PACKAGE_NAME" ] ; then
  rm -rf $PACKAGE_NAME
  echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Removed existing package if any"  
 
fi

HOME_DIR=$(pwd)
if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit
git checkout "$PACKAGE_VERSION"
# Install symfony/error-handler on compatible PHP versions to avoid a deprecation warning of the old DebugClassLoader and ErrorHandler classes
composer require --no-update --dev symfony/error-handler "^4.4 || ^5.0"
composer update
if ! composer install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit
if ! ./scripts/pear.sh run-tests -r tests; then
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

#Test is in parity with intel.
#TOTAL TIME: 03:21
#664 PASSED TESTS
#15 SKIPPED TESTS
#30 FAILED TESTS:
#/root/pear-core/tests/PEAR_DependencyDB/test_assertDepsDB.phpt
#/root/pear-core/tests/PEAR_DependencyDB/test_assertDepsDB_fail.phpt
#/root/pear-core/tests/PEAR_DependencyDB/test_dependsOn.phpt
#/root/pear-core/tests/PEAR_DependencyDB/test_installPackage.phpt
#/root/pear-core/tests/PEAR_DependencyDB/test_rebuildDB.phpt
#/root/pear-core/tests/PEAR_DependencyDB/test_uninstallPackage.phpt
#/root/pear-core/tests/PEAR_Installer/test_install_complexlocalpackage.phpt
#/root/pear-core/tests/PEAR_Installer/test_install_complexlocalpackage2.phpt
#/root/pear-core/tests/PEAR_Installer/test_install_complexlocalpackage2_force.phpt
#/root/pear-core/tests/PEAR_Installer/test_install_complexlocalpackage2_ignore-errors.phpt
#/root/pear-core/tests/PEAR_Installer/test_install_complexlocalpackage2_ignore-errorssoft.phpt
#/root/pear-core/tests/PEAR_Installer/test_install_multiple2.phpt
#/root/pear-core/tests/PEAR_Installer/test_install_simplelocalpackage_installroot.phpt
#/root/pear-core/tests/PEAR_Installer/test_install_simplelocalpackage_packagingroot.phpt
#/root/pear-core/tests/PEAR_Installer/test_install_subpackage.phpt
#/root/pear-core/tests/PEAR_Installer/test_install_subpackage_fail.phpt
#/root/pear-core/tests/PEAR_Installer/test_uninstall_complex_params_invalid1.phpt
#/root/pear-core/tests/PEAR_Installer/test_uninstall_complex_params_invalid2.phpt
#/root/pear-core/tests/PEAR_Installer/test_uninstall_complex_params_ok.phpt
#/root/pear-core/tests/PEAR_Installer/test_uninstall_optionaldep.phpt
#/root/pear-core/tests/PEAR_Installer/test_uninstall_simple_params_ok.phpt
#/root/pear-core/tests/PEAR_Installer/test_upgrade_complexlocalpackage2.phpt
#/root/pear-core/tests/PEAR_Installer/test_upgrade_subpackage.phpt
#/root/pear-core/tests/PEAR_Registry/api1_1/test_addPackage.phpt
#/root/pear-core/tests/PEAR_Registry/api1_1/test_addPackage2.phpt
#/root/pear-core/tests/PEAR_Registry/api1_1/test_deletePackage.phpt
#/root/pear-core/tests/PEAR_Registry/api1_1/test_deletePackage_pfv2.phpt
#/root/pear-core/tests/PEAR_Registry/api1_1/test_getInstalledGroup.phpt
#/root/pear-core/tests/PEAR_Registry/api1_1/test_updatePackage.phpt
#/root/pear-core/tests/PEAR_Registry/api1_1/test_updatePackage2.phpt