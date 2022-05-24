#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : jekyll-commonmark
# Version       : v1.2.0
# Source repo   : https://github.com/pathawks/jekyll-commonmark
# Tested on     : UBI: 8.5
# Language      : Node
# Travis-Check  : True
# Script License: MIT License
# Maintainer    : Shreya Kajbaje <shreya.kajbaje@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jekyll-commonmark
PACKAGE_VERSION=${1:-v1.2.0}
PACKAGE_URL=https://github.com/pathawks/jekyll-commonmark

yum -y update && yum install -y nodejs nodejs-devel nodejs-packaging npm python38 python38-devel ncurses git jq curl make gcc-c++ procps gnupg2 ruby libcurl-devel libffi-devel ruby-devel redhat-rpm-config sqlite sqlite-devel java-1.8.0-openjdk-devel rubygem-rake wget

#yum groupinstall "Development Tools"
yum install openssl-devel
wget https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.1.tar.gz
tar xvfvz ruby-2.7.1.tar.gz
cd ruby-2.7.1
./configure
make
make install

git clone $PACKAGE_URL
cd /jekyll-commonmark
git checkout $PACKAGE_VERSION

#gem install bundler -v 1.17.3
gem install bundler:1.17.3 --default
gem install rake
gem install kramdown-parser-gfm
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable

export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

source /etc/profile.d/rvm.sh;
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

gem install kramdown-parser-gfm

gem install bundler -v 1.17.3
bundle install --jobs=3 --retry=3 --path=${BUNDLE_PATH:-vendor/bundle}

function test_with_ruby(){
        echo "Automation via Ruby version 2.7"

        #cd $PACKAGE_NAME
        #git checkout $PACKAGE_VERSION

        if test -f "script/cibuild"; then
                chmod u+x script/cibuild
                if ! script/cibuild; then
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
        elif test -f ".rspec"; then
                if ! bundle _1.17.3_ exec rspec; then
                        if ! bundle exec rspec; then
                                echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                                echo "$PACKAGE_URL $PACKAGE_NAME"
                                echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"

                                exit 1
                        fi
                else
                        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                        echo "$PACKAGE_URL $PACKAGE_NAME"
                        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
                        exit 0
                fi
        elif test -f "Rakefile"; then
                if ! bundle _1.17.3_ exec rake; then
                        if ! bundle exec rake; then
                                echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
                                echo "$PACKAGE_URL $PACKAGE_NAME"
                                echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
                                exit 1
                        fi
                else
                        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
                        echo "$PACKAGE_URL $PACKAGE_NAME"
                        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
                        exit 0
                fi
        else
                echo "------------------$PACKAGE_NAME:install_success_&_test_NA-------------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success_and_Test_NA"
                exit 0
        fi
}

test_with_ruby