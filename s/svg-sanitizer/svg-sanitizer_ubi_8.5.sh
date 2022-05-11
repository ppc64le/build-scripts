#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: svg-sanitizer
# Version	: 0.13.0
# Source repo	: https://github.com/darylldoyle/svg-sanitizer
# Tested on	: UBI: 8.5
# Language      : PHP
# Travis-Check  : True
# Script License: GPL-2.0 License
# Maintainer	: Vishaka Desai <Vedang.Wartikar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=svg-sanitizer
PACKAGE_VERSION=${1:-0.13.0}
PACKAGE_URL=https://github.com/darylldoyle/svg-sanitizer

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl nodejs make gcc-c++
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y git bzip2 ca-certificates curl tar xz openssl  wget  gzip gcc-c++ make pkgconf  file curl-devel  libxml2-devel openssl-devel sqlite-devel ncurses-devel libjpeg-devel libicu-devel libtidy-devel libxslt-devel libzip-devel bzip2-devel libpng-devel diffutils autoconf patch
yum install -y http://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/Packages/readline-devel-7.0-10.el8.ppc64le.rpm
yum install -y https://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/Packages/oniguruma-devel-6.8.2-2.el8.ppc64le.rpm

yum install -y php php-json php-xml php-mbstring

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer
composer require --dev phpunit/phpunit --with-all-dependencies ^8

yum install git

mkdir -p output

set -x
install_test_success_update()
{
  echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
  echo "$PACKAGE_URL $PACKAGE_NAME" > /output/test_success
  echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /output/version_tracker
  exit 0
}

install_test_fail_update()
{
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /output/test_fails 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /output/version_tracker
	exit 0
}

install_test_NA_update()
{
	echo 
    echo "------------------$PACKAGE_NAME:install_success_&_test_NA-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME" > /output/test_success 
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success_and_Test_NA" > /output/version_tracker
    exit 0
}

set_phpunit_params()
{
	exact_phpunit_ver=$(./vendor/phpunit/phpunit/phpunit --version | head -1 | cut -f2 -d " ")
	if [[ $exact_phpunit_ver == 4* ]] || [[ $exact_phpunit_ver == 5* ]] || [[ $exact_phpunit_ver == 6* ]];then
		phpunit_param=""
	else
		phpunit_param="--dont-report-useless-tests"
	fi
}

try_multiple_test_patterns()
{
	if ! ( ./vendor/phpunit/phpunit/phpunit . $phpunit_param );then
			
		if ! ( (./vendor/phpunit/phpunit/phpunit | grep "Code coverage needs to be enabled in php.ini by setting 'xdebug.mode' to 'coverage'") && php -dxdebug.mode=coverage ./vendor/phpunit/phpunit/phpunit );then
			#case of output-formatters
			if ! ( (./vendor/phpunit/phpunit/phpunit | grep "API docuementation out of date. Run 'composer api' to update" ) && composer api && ./vendor/phpunit/phpunit/phpunit );then
				TEST_SUCCESS="false"
			else
				install_test_success_update
			fi
		else
			install_test_success_update
		fi				
	else
		install_test_success_update
	fi
}

OS_NAME=$(python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])")

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
  	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /output/version_tracker
  	exit 0
fi

cd /$PACKAGE_NAME
git checkout $PACKAGE_VERSION

INSTALL_SUCCESS="false"
for phpver in 7.3.28 8.0.7
do
	# phpenv global $phpver
	echo "Running composer install with $phpver" 
	if ! composer install; then
		#This is to cover install failure with error like require-dev.mikey179/vfsStream is invalid, it should not contain uppercase characters. Please use mikey179/vfsstream instead
		#for consolidation__robo_1.4.9 and 1.4.6 
		#justinrainbow__json-schema_5.2.9/install.fails.log:  require-dev.json-schema/JSON-Schema-Test-Suite is invalid, it should not contain uppercase characters. Please use json-schema/json-schema-test-suite instead.
		
		case_sensitive_packages="mikey179/vfsStream natxet/CssMin json-schema/JSON-Schema-Test-Suite consolidation/Robo"
		for package in $case_sensitive_packages
		do
			if grep $package composer.json; then
				package_string=$(echo $package | cut -f2 -d "/")
				expected_package_string=$(echo $package_string | tr '[:upper:]' '[:lower:]')
				sed -i "s/${package_string}/${expected_package_string}/g" composer.json
			fi
		done

		echo "Running composer update"
		composer update
		echo "Running composer install with $phpver after composer update"
		if ! composer install; then
			INSTALL_SUCCESS="false"
		else
			INSTALL_SUCCESS="true"
			break
		fi
	else
		INSTALL_SUCCESS="true"
		break
	fi
done

if [ $INSTALL_SUCCESS == "false" ]
then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /output/install_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails" > /output/version_tracker
	exit 0
fi

cd /$PACKAGE_NAME
echo "Checking for Test files"
#Flag for test results
TEST_SUCCESS="false"
if [ $(find . -name "*Test*" | grep -v "IntlTestHelper" | wc -l) -gt 0 ];then
	if ! ./vendor/phpunit/phpunit/phpunit;then
		set_phpunit_params
		try_multiple_test_patterns
	else
		install_test_success_update		
	fi
		
	echo "Some package unit test works with older phpunit so trying unit tests with multiple versions"
	for phpunitver in 9 8 7 6 5
	do	
		composer require --with-all-dependencies --dev phpunit/phpunit ^${phpunitver}
		#setting params to use with phpunit command
		set_phpunit_params
			
		try_multiple_test_patterns

		composer remove --with-all-dependencies --dev phpunit/phpunit ^${phpunitver}
	done
			
	#packages like symfony/dependency-injection needs some class from phpunit-bridge
	echo "Some package needs symfony/phpunit-bridge so trying unit tests with it"
	for phpunitver in 9 8 7 6 5
	do	
		composer require --with-all-dependencies --dev symfony/phpunit-bridge phpunit/phpunit ^${phpunitver}

		set_phpunit_params
		
		if ! ( ./vendor/phpunit/phpunit/phpunit . ${phpunit_param} );then
			TEST_SUCCESS="false"
		else
			install_test_success_update
		fi
		composer remove --with-all-dependencies --dev symfony/phpunit-bridge phpunit/phpunit ^${phpunitver}
	done
	
	if [ $TEST_SUCCESS == "false" ]
	then
		install_test_fail_update
	fi
else
	install_test_NA_update
fi