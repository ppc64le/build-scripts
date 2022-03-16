#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: {package_name}
# Version	: {package_version}
# Source repo	: {package_url}
# Tested on	: {distro_name} {distro_version}
# Language      : PHP
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation {maintainer}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=${PACKAGE_NAME}
PACKAGE_VERSION=${PACKAGE_VERSION}
PACKAGE_URL=${PACKAGE_URL}

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl nodejs make gcc-c++ yum-utils

yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum-config-manager --add-repo http://mirror.centos.org/centos/8/AppStream/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/PowerTools/ppc64le/os/ && yum-config-manager --add-repo http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/

wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y git bzip2 ca-certificates curl tar xz openssl  wget  gzip gcc-c++ make pkgconf  file curl-devel  libxml2-devel openssl-devel sqlite-devel ncurses-devel libjpeg-devel libicu-devel libtidy-devel libxslt-devel libzip-devel bzip2-devel libpng-devel diffutils autoconf patch bison re2c readline-devel oniguruma-devel glibc fontconfig php-mbstring

mkdir -p /home/tester/output
cd /home/tester

# Install phantomjs, as its needed for some dependencies
wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2
tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2
ln -sf phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/local/bin/phantomjs
export PATH=$PATH:/usr/local/bin/phantomjs

curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | bash
export PHP_VERSION_73="7.3.28"
export PHP_VERSION_74="7.4.20"
export PHP_VERSION_80="8.0.7"

export PATH="/root/.phpenv/bin:${PATH}"

#to list versions available for install
phpenv install -l
phpenv install ${PHP_VERSION_73}
phpenv install ${PHP_VERSION_74}
phpenv install ${PHP_VERSION_80}

eval "$(phpenv init -)"

#to switch to an already installed version
phpenv global ${PHP_VERSION_73}

ln -s /root/.phpenv/shims/php /usr/bin/php
#RUN ls -s /root/.phpenv/bin/phpenv  /usr/bin/phpenv
PATH="/root/.phpenv/bin:${PATH}"

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && php composer-setup.php --install-dir=/bin --filename=composer

composer require --dev phpunit/phpunit --with-all-dependencies 

export CRYPTOGRAPHY_DONT_BUILD_RUST=1
pip3 install --upgrade homeassistant
yum -y install rustc
yum -y install cargo
sudo pip3 install setuptools_rust
pip3 install --user --upgrade nox

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
  	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
  	exit 1
fi

cd $PACKAGE_NAME

python3 -m nox
