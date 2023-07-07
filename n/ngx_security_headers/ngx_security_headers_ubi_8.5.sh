#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ngx_security_headers
# Version       : 0.0.9
# Source repo   : https://github.com/GetPageSpeed/ngx_security_headers.git
# Tested on     : ubi 8.5
# Language      : c
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Sachin K {sachin.kakatkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./ngx_security_headers_ubi_8.5.sh 0.0.9(version_to_test)
PACKAGE_NAME=ngx_security_headers
PACKAGE_VERSION=${1:-0.0.9}
PACKAGE_URL=https://github.com/GetPageSpeed/ngx_security_headers.git

dnf install git sudo make gcc gcc-c++ automake autoconf perl libtool openssl openssl-devel pcre zlib zlib-devel pcre2 pcre2-devel pcre-devel cpanminus -y
mkdir -p /home/tester/output
cd /home/tester

rm -rf $PACKAGE_NAME

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
cd ..
git clone https://github.com/nginx/nginx.git
cd nginx
./auto/configure --with-compat --add-module=../ngx_security_headers

if ! (make); then
       echo "------------------$PACKAGE_NAME:build failed---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  build_Fails"
       exit 1
fi

make install
cd ..
export PATH=$PATH:$(pwd)/nginx/objs
cpanm --notest --local-lib=$HOME/perl5 Test::Nginx
cd $PACKAGE_NAME

if ! (PERL5LIB=$HOME/perl5/lib/perl5 TEST_NGINX_VERBOSE=true prove -v); then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi  

