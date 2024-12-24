#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : 3scale-apisonator
# Version               : 3scale-2.14.1-GA
# Source repo           : https://github.com/3scale/apisonator
# Tested on             : UBI:9.3
# Language              : Ruby
# Travis-Check          : True
# Script License        : Apache License 2.0 or later
# Maintainer            : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-3scale-2.14.1-GA}
PACKAGE_NAME=apisonator
PACKAGE_URL=https://github.com/3scale/apisonator.git

yum install -y make wget gcc gcc-c++ autoconf automake glibc-headers \
    glibc-devel openssl-devel git procps ncurses-devel m4 \
    redhat-rpm-config xz info libyaml-devel zlib-devel ruby-devel \
    https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/bison-3.7.4-5.el9.ppc64le.rpm \
    https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/readline-devel-8.1-4.el9.ppc64le.rpm

curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
curl -L https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh

rvm install ruby-3.3.0

gem install bundle

git clone https://github.com/twitter/twemproxy.git
cd twemproxy
autoreconf -fvi
./configure --prefix=/opt/twemproxy
make
make install
cd ../

#Install redis and configure the server
wget http://download.redis.io/releases/redis-7.0.5.tar.gz
tar xzf redis-7.0.5.tar.gz
cd redis-7.0.5
make
make install
mkdir -p /etc/redis
cp redis.conf /etc/redis/redis.conf
redis-server /etc/redis/redis.conf --daemonize yes
sed -i 's/port 6379/port 7379/' /etc/redis/redis.conf
redis-server /etc/redis/redis.conf --daemonize yes
sed -i 's/port 7379/port 7380/' /etc/redis/redis.conf
redis-server /etc/redis/redis.conf --daemonize yes
sed -i 's/port 7380/port 22121/' /etc/redis/redis.conf
redis-server /etc/redis/redis.conf --daemonize yes

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

if ! bundle install ; then
      echo "------------------$PACKAGE_NAME::Install_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail | Install_fails"
	  exit 1
fi

if ! ruby -Itest test/unit/validators/key_test.rb ; then
       echo "------------------$PACKAGE_NAME:Key_test_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION  | GitHub | Fail |  key_test_Fails"
       exit 2
fi

if ! ruby -Itest test/unit/validators/limits_test.rb ; then
       echo "------------------$PACKAGE_NAME:limits_test_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION  | GitHub | Fail |  limit_test_Fails"
       exit 1
fi

if ! ruby -Itest test/unit/worker_test.rb  ; then
      echo "------------------$PACKAGE_NAME::Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION |  GitHub  | Fail|  Test_fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION |  GitHub  | Pass |  Test_Success"
      exit 0
fi