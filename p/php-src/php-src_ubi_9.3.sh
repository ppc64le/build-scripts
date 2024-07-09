#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : php-src
# Version          : php-8.4.0alpha1
# Source repo      : https://github.com/php/php-src
# Tested on        : UBI:9.3
# Language         : PHP
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=php-src
PACKAGE_VERSION=${1:-php-8.4.0alpha1}
PACKAGE_URL=https://github.com/php/php-src

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

yum install -y git wget expect
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install -y re2c bison autoconf make libtool ccache libxml2-devel sqlite-devel glibc-gconv-extra pcre expect

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./buildconf --force ; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_fails"
        exit 1
fi

if ! ./configure --enable-debug ; then
       echo "------------------$PACKAGE_NAME::Configure_fails-------------------------"
       echo "$PACKAGE_URL $PACKAGE_NAME"
       echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Configure_fails"
       exit 1
fi

if ! make -j$(/usr/bin/nproc) && make install; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi
export SKIP_SLOW_TESTS=1
export SKIP_IO_CAPTURE_TESTS=1
# Run the tests
if ! sapi/cli/php run-tests.php -P -q --asan -d opcache.jit=tracing -d opcache.jit_buffer_size=64M -d opcache.jit=disable -d opcache.protect_memory=1 -d opcache.jit_buffer_size=64M -j4 -g FAIL,BORK,LEAK,XLEAK --no-progress --offline --show-diff --show-slow 1000 --set-timeout 120; then
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
