#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: presto
# Version	: 0.267
# Source repo	: https://github.com/prestodb/presto.git
# Tested on	: RHEL 8.3
# Language      : Java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer	: Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=presto
PACKAGE_VERSION=${1:-0.267}
PACKAGE_URL=https://github.com/prestodb/presto.git

CWD=`pwd`
cd $HOME

sudo yum install -y java-1.8.0-openjdk maven python38-devel diffutils libxml2-devel libxslt-devel gcc make git wget

JDK_PATHS=$(compgen -G '/usr/lib/jvm/java-1.8.0-openjdk-*')
export JAVA_HOME=${JDK_PATHS%$'\n'*}
export PATH=$JAVA_HOME/bin:$PATH
export JAVA_OPTS="-Xmx2048M -Xss512M -XX:MaxPermSize=2048M -XX:+CMSClassUnloadingEnabled -XX:+UseConcMarkSweepGC"

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply $CWD/patches/presto-main.patch
git apply $CWD/patches/presto-tests.patch
./mvnw clean install -DskipTests

cd $HOME
TMPDIR=$HOME/tmpdir

# Modify embedded-redis-0.6.jar to contain ppc64le redis-server
mkdir $TMPDIR
cd $TMPDIR
wget http://download.redis.io/releases/redis-3.2.8.tar.gz
tar -zxvf redis-3.2.8.tar.gz
rm -rf redis-3.2.8.tar.gz
cd redis-3.2.8/
make
mkdir redisjar
cd redisjar/
mv ~/.m2/repository/com/orange/redis-embedded/embedded-redis/0.6/embedded-redis-0.6.jar .
jar xf embedded-redis-0.6.jar
rm -rf embedded-redis-0.6.jar
rm -rf redis/2.8.5/linux/redis-server
rm -rf redis/2.8.9/linux/redis-server
cp ../src/redis-server redis/2.8.5/linux/
cp ../src/redis-server redis/2.8.9/linux/
jar cf embedded-redis-0.6.jar META-INF redis
cp embedded-redis-0.6.jar ~/.m2/repository/com/orange/redis-embedded/embedded-redis/0.6/
cd $HOME
rm -rf $TMPDIR

# Modify hadoop-apache2-2.7.4-9.jar to contain native hadoop and snappy libraries
mkdir $TMPDIR
cd $TMPDIR
wget https://downloads.apache.org/bigtop/bigtop-3.0.0/repos/GPG-KEY-bigtop
sudo rpm --import GPG-KEY-bigtop
rm -rf GPG-KEY-bigtop
sudo wget -O /etc/yum.repos.d/bigtop.repo https://downloads.apache.org/bigtop/bigtop-3.0.0/repos/centos-8/bigtop.repo
sudo yum install -y hadoop hadoop-client
git clone https://github.com/prestodb/presto-hadoop-apache2.git
cd presto-hadoop-apache2/
git checkout 2.7.4-9
rm -rf ./src/main/resources/nativelib/Linux-ppc64le/*
cp /usr/lib/hadoop/lib/native/libhadoop.so.1.0.0 ./src/main/resources/nativelib/Linux-ppc64le/libhadoop.so
cp /usr/lib/hadoop/lib/native/libsnappy.so.1.1.8 ./src/main/resources/nativelib/Linux-ppc64le/libsnappy.so
mvn package
cp ./target/hadoop-apache2-2.7.4-9.jar ~/.m2/repository/com/facebook/presto/hadoop/hadoop-apache2/2.7.4-9/hadoop-apache2-2.7.4-9.jar
cd $HOME
rm -rf $TMPDIR

# Modify snappy-java-1.1.7.1.jar to contain snappyjava library
mkdir $TMPDIR
cd $TMPDIR
sudo subscription-manager repos --enable codeready-builder-for-rhel-8-ppc64le-rpms
sudo yum install -y gcc-c++ libstdc++-static cmake
git clone https://github.com/xerial/snappy-java.git
cd snappy-java/
git checkout 1.1.7.1
make jni-header
make clean-native native
cd ../
mv ~/.m2/repository/org/xerial/snappy/snappy-java/1.1.7.1/snappy-java-1.1.7.1.jar .
jar xf snappy-java-1.1.7.1.jar
rm -rf snappy-java-1.1.7.1.jar
rm -rf org/xerial/snappy/native/Linux/ppc64le/libsnappyjava.so
cp snappy-java/target/snappy-1.1.7-Linux-ppc64le/libsnappyjava.so ./org/xerial/snappy/native/Linux/ppc64le/
jar cf snappy-java-1.1.7.1.jar META-INF org
cp snappy-java-1.1.7.1.jar ~/.m2/repository/org/xerial/snappy/snappy-java/1.1.7.1/
cd $HOME
rm -rf $TMPDIR

# Modify testing-postgresql-server-9.6.3-4.jar to include ppc64le postgresql
mkdir $TMPDIR
cd $TMPDIR
sudo yum install -y cpio postgresql postgresql-server postgresql-contrib postgresql-libs
wget https://vault.centos.org/8.5.2111/AppStream/ppc64le/os/Packages/postgresql-10.17-2.module_el8.5.0+865+7313c562.ppc64le.rpm
wget https://vault.centos.org/8.5.2111/AppStream/ppc64le/os/Packages/postgresql-server-10.17-2.module_el8.5.0+865+7313c562.ppc64le.rpm
wget https://vault.centos.org/8.5.2111/AppStream/ppc64le/os/Packages/postgresql-contrib-10.17-2.module_el8.5.0+865+7313c562.ppc64le.rpm
wget https://vault.centos.org/8.5.2111/AppStream/ppc64le/os/Packages/libpq-13.3-1.el8_4.ppc64le.rpm
rpm2cpio postgresql-10.17-2.module_el8.5.0+865+7313c562.ppc64le.rpm | cpio -idmv
rpm2cpio postgresql-contrib-10.17-2.module_el8.5.0+865+7313c562.ppc64le.rpm | cpio -idmv
rpm2cpio postgresql-server-10.17-2.module_el8.5.0+865+7313c562.ppc64le.rpm | cpio -idmv
rpm2cpio libpq-13.3-1.el8_4.ppc64le.rpm | cpio -idmv
mkdir pgjar
cd pgjar
mv ~/.m2/repository/com/facebook/airlift/testing-postgresql-server/9.6.3-4/testing-postgresql-server-9.6.3-4.jar .
jar xf testing-postgresql-server-9.6.3-4.jar
rm -rf testing-postgresql-server-9.6.3-4.jar
mkdir postgresql-Linux-ppc64le
tar xzf postgresql-Linux-amd64.tar.gz -C postgresql-Linux-ppc64le
cd postgresql-Linux-ppc64le
mkdir lib64
mkdir libexec
rm -rf bin/*
rm -rf lib/*
rm -rf share/*
cp $TMPDIR/usr/bin/pg_ctl bin/
cp $TMPDIR/usr/bin/postgres bin/
cp $TMPDIR/usr/bin/initdb bin/
cp -r $TMPDIR/usr/lib/* lib/
cp -r $TMPDIR/usr/lib64/* lib64/
cp -r $TMPDIR/usr/libexec/* libexec/
cp -r $TMPDIR/usr/share/* share/
tar czf postgresql-Linux-ppc64le.tar.gz bin lib share lib64 libexec
mv postgresql-Linux-ppc64le.tar.gz ../
cd ..
jar cf testing-postgresql-server-9.6.3-4.jar com META-INF postgresql-Linux-amd64.tar.gz postgresql-Linux-ppc64le.tar.gz postgresql-Mac_OS_X-x86_64.tar.gz
cp testing-postgresql-server-9.6.3-4.jar ~/.m2/repository/com/facebook/airlift/testing-postgresql-server/9.6.3-4/
sudo mkdir /var/run/postgresql/
sudo chown $USER:$USER /var/run/postgresql/
cd $HOME
rm -rf $TMPDIR

# Modify testing-mysql-server-5-0.6.jar to add mysql ppc64le to it
mkdir $TMPDIR
cd $TMPDIR
sudo yum install -y xz
git clone https://github.com/prestodb/testing-mysql-server.git
cd testing-mysql-server
git checkout tags/0.7
sed -i 's/PPC64LE_BASEURL="http:\/\/yum.mariadb.org\/10.2\/centos\/7\/ppc64le\/rpms\/"/PPC64LE_BASEURL="https:\/\/yum.mariadb.org\/10.3\/centos8-ppc64le\/rpms\/"/g' testing-mysql-server-5/repack-mysql-5.sh
sed -i 's/LINUX_PPC64LE_RPM=MariaDB-server-10.2.36-1.el7.centos.ppc64le.rpm/LINUX_PPC64LE_RPM=MariaDB-server-10.3.32-1.el8.ppc64le.rpm/g' testing-mysql-server-5/repack-mysql-5.sh
sed -i '/$STRIP bin\/mysqld/d' testing-mysql-server-5/repack-mysql-5.sh
sed -i '/$STRIP bin\/mysqld/d' testing-mysql-server-8/repack-mysql-8.sh
mvn package -DskipTests
rm -rf ~/.m2/repository/com/facebook/presto/testing-mysql-server-base/0.6/testing-mysql-server-base-0.6.jar
rm -rf ~/.m2/repository/com/facebook/presto/testing-mysql-server-5/0.6/testing-mysql-server-5-0.6.jar
cp testing-mysql-server-base/target/testing-mysql-server-base-0.7.jar ~/.m2/repository/com/facebook/presto/testing-mysql-server-base/0.6/testing-mysql-server-base-0.6.jar
cp testing-mysql-server-5/target/testing-mysql-server-5-0.7.jar ~/.m2/repository/com/facebook/presto/testing-mysql-server-5/0.6/testing-mysql-server-5-0.6.jar
cd $HOME
rm -rf $TMPDIR

# Make sure that the current user can run docker and the necessary docker images for presto-prometheus tests are available
mkdir $TMPDIR
cd $TMPDIR
sudo usermod -aG docker $USER
git clone https://github.com/testcontainers/moby-ryuk.git
cd moby-ryuk
git checkout 0.3.0
docker build -t testcontainers/ryuk:0.3.0 .
docker pull prom/prometheus:v2.21.0
docker tag prom/prometheus:v2.21.0 prom/prometheus:v2.15.1
cd $HOME
rm -rf $TMPDIR

cd presto
./mvnw clean install

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"

