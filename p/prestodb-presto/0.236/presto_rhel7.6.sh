# ----------------------------------------------------------------------------
#
# Package        : presto
# Version        : 0.236
# Source repo    : https://github.com/prestodb/presto.git
# Tested on      : RHEL 7.6
# Script License : Apache License, Version 2 or later
# Maintainer     : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

CWD=`pwd`

sudo -s <<RTD

# Install build dependencies
yum install -y --nogpgcheck git gcc gcc-c++ make cmake bison tar python ant \
	ncurses-devel perl-Data-Dumper which wget gzip openssl openssl-devel \
	java-1.8.0-openjdk-devel snappy automake autoconf \
	gcc-c++ libgcc gcc

# Install mysql, postgresql, hadoop as build dependencies
yum install -y rh-mysql57
cd /etc/yum.repos.d/
wget http://public-repo-1.hortonworks.com/HDP/centos7-ppc/2.x/updates/2.6.1.0/hdp.repo
yum install -y hadoop_2_6_1_0_129 hadoop_2_6_1_0_129-client
yum install -y redis

wget ftp://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL7/gpg-pubkey-6976a827-5164221b
rpm --import gpg-pubkey-6976a827-5164221b
rm -rf gpg-pubkey-6976a827-5164221b
cat > /etc/yum.repos.d/advance-toolchain.repo << EOF
# Begin of configuration file
[advance-toolchain]
name=Advance Toolchain IBM FTP
baseurl=ftp://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL7
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=ftp://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL7/gpg-pubkey-6976a827-5164221b
# End of configuration file
EOF
yum install -y advance-toolchain-at10.0-runtime
yum install -y https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7.6-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
yum install -y postgresql96 postgresql96-server postgresql96-contrib postgresql96-libs

yum install -y jansi-native unzip

RTD

cd $CWD

# Download and unpack apache maven
wget https://archive.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzf apache-maven-3.6.3-bin.tar.gz
rm -rf apache-maven-3.6.3-bin.tar.gz

# Set environment variables
export MAVEN_HOME=$CWD/apache-maven-3.6.3
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export JAVA_OPTS="-Xmx2048M -Xss512M -XX:MaxPermSize=2048M -XX:+CMSClassUnloadingEnabled -XX:+UseConcMarkSweepGC"
export PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH
source scl_source enable rh-mysql57

TMPDIR=$CWD/tmpdir
mkdir $TMPDIR

# Clone presto 0.236, build and execute tests
git clone https://github.com/prestodb/presto.git
cd presto
PRESTODIR=`pwd`
git checkout tags/0.236
# Ignore the tests from TestSqlStageExecution.java, TestTimeZoneUtils.java which fail on intel as well:
# TestSqlStageExecution.testFinalStageInfo:91->testFinalStageInfoInternal:145 ? OutOfMemory
# TestTimeZoneUtils.test:70 ? TimeZoneNotSupported Time zone not supported: America/Nuuk
git apply $CWD/presto-main.patch
./mvnw clean install -DskipTests

# Modify testing-mysql-server-5-0.6.jar to add mysql ppc64le to it
cd $TMPDIR
mv ~/.m2/repository/com/facebook/presto/testing-mysql-server-5/0.6/testing-mysql-server-5-0.6.jar .
jar xf testing-mysql-server-5-0.6.jar
rm -rf testing-mysql-server-5-0.6.jar
mkdir mysql-Linux-ppc64le
tar xzf mysql-Linux-amd64.tar.gz -C mysql-Linux-ppc64le
cd mysql-Linux-ppc64le
rm -rf bin/mysqld
rm -rf share/*
cp /opt/rh/rh-mysql57/root/usr/libexec/mysqld bin/
cp -r /opt/rh/rh-mysql57/root/usr/share/rh-mysql57-mysql/* share/
tar czf mysql-Linux-ppc64le.tar.gz bin COPYING docs README share
mv mysql-Linux-ppc64le.tar.gz ../
cd ..
jar cf testing-mysql-server-5-0.6.jar com META-INF mysql-Linux-amd64.tar.gz mysql-Linux-ppc64le.tar.gz mysql-Mac_OS_X-x86_64.tar.gz
cp testing-mysql-server-5-0.6.jar ~/.m2/repository/com/facebook/presto/testing-mysql-server-5/0.6/

# Modify hadoop-apache2-2.7.4-7.jar to contain native hadoop and snappy libraries
cd $TMPDIR
rm -rf *
mv ~/.m2/repository/com/facebook/presto/hadoop/hadoop-apache2/2.7.4-7/hadoop-apache2-2.7.4-7.jar .
jar xf hadoop-apache2-2.7.4-7.jar
rm -rf hadoop-apache2-2.7.4-7.jar
rm -rf nativelib/Linux-ppc64le/*
cp /usr/hdp/2.6.1.0-129/hadoop/lib/native/libhadoop.so.1.0.0 nativelib/Linux-ppc64le/libhadoop.so
cp /usr/hdp/2.6.1.0-129/hadoop/lib/native/libsnappy.so.1.1.4 nativelib/Linux-ppc64le/libsnappy.so
jar cf hadoop-apache2-2.7.4-7.jar com common-version-info.properties core-default.xml core-site.xml hdfs-default.xml mapred-default.xml META-INF nativelib org org.apache.hadoop.application-classloader.properties
mv hadoop-apache2-2.7.4-7.jar ~/.m2/repository/com/facebook/presto/hadoop/hadoop-apache2/2.7.4-7/hadoop-apache2-2.7.4-7.jar

# Modify snappy-java-1.1.7.1.jar to contain snappyjava library
cd $TMPDIR
rm -rf *
cp /usr/hdp/2.6.1.0-129/hadoop/client/snappy-java.jar .
jar xf snappy-java.jar
rm -rf snappy-java.jar
mkdir maven_snappy_java
cd maven_snappy_java
mv ~/.m2/repository/org/xerial/snappy/snappy-java/1.1.7.1/snappy-java-1.1.7.1.jar .
jar xf snappy-java-1.1.7.1.jar
rm -rf snappy-java-1.1.7.1.jar
rm -rf org/xerial/snappy/native/Linux/ppc64le/libsnappyjava.so
cp ../org/xerial/snappy/native/Linux/ppc64le/libsnappyjava.so ./org/xerial/snappy/native/Linux/ppc64le/
jar cf snappy-java-1.1.7.1.jar META-INF org
cp snappy-java-1.1.7.1.jar ~/.m2/repository/org/xerial/snappy/snappy-java/1.1.7.1/

# Modify testing-postgresql-server-9.6.3-4.jar to include ppc64le postgresql
cd $TMPDIR
rm -rf *
mv ~/.m2/repository/com/facebook/airlift/testing-postgresql-server/9.6.3-4/testing-postgresql-server-9.6.3-4.jar .
jar xf testing-postgresql-server-9.6.3-4.jar
rm -rf testing-postgresql-server-9.6.3-4.jar
mkdir postgresql-Linux-ppc64le
tar xzf postgresql-Linux-amd64.tar.gz -C postgresql-Linux-ppc64le
cd postgresql-Linux-ppc64le
rm -rf bin/*
rm -rf lib/*
rm -rf share/*
cp /usr/pgsql-9.6/bin/pg_ctl bin/
cp /usr/pgsql-9.6/bin/postgres bin/
cp /usr/pgsql-9.6/bin/initdb bin/
cp -r /usr/pgsql-9.6/lib/* lib/
cp -r /usr/pgsql-9.6/share/* share/
tar czf postgresql-Linux-ppc64le.tar.gz bin lib share
mv postgresql-Linux-ppc64le.tar.gz ../
cd ..
jar cf testing-postgresql-server-9.6.3-4.jar com META-INF postgresql-Linux-amd64.tar.gz postgresql-Linux-ppc64le.tar.gz postgresql-Mac_OS_X-x86_64.tar.gz
cp testing-postgresql-server-9.6.3-4.jar ~/.m2/repository/com/facebook/airlift/testing-postgresql-server/9.6.3-4/

# Modify embedded-redis-0.6.jar to contain ppc64le redis-server
cd $TMPDIR
rm -rf *
mv ~/.m2/repository/com/orange/redis-embedded/embedded-redis/0.6/embedded-redis-0.6.jar .
jar xf embedded-redis-0.6.jar
rm -rf embedded-redis-0.6.jar
rm -rf redis/2.8.5/linux/redis-server
cp /usr/bin/redis-server redis/2.8.5/linux/redis-server
rm -rf redis/2.8.9/linux/redis-server
cp /usr/bin/redis-server redis/2.8.9/linux/redis-server
jar cf embedded-redis-0.6.jar META-INF redis
cp embedded-redis-0.6.jar ~/.m2/repository/com/orange/redis-embedded/embedded-redis/0.6/

# Create /var/run/postgresql and change ownership to current non-root user
USER=`whoami`
sudo -s << RTD

mkdir /var/run/postgresql/
sudo chown $USER:$USER /var/run/postgresql/

RTD

# Re-build with tests
echo "===================================== Re-build with tests begin ==========================================="
cd $PRESTODIR
ulimit -u unlimited
./mvnw clean install
echo "===================================== Re-build with tests end ============================================="

# Modify presto-cli to resolve the native libjansi.so related issue
cd $TMPDIR
rm -rf *
mkdir presto-cli
cd presto-cli
cp $PRESTODIR/presto-cli/target/presto-cli-0.236-executable.jar .
unzip -q presto-cli-0.236-executable.jar
rm -rf presto-cli-0.236-executable.jar
rm -rf META-INF/native/linux64/libjansi.so
mkdir tmp_local_jansi-native
cd tmp_local_jansi-native
cp /usr/lib/java/jansi-native-linux64.jar .
jar xf jansi-native-linux64.jar
cp META-INF/native/linux64/libjansi.so ../META-INF/native/linux64/
cd ..
rm -rf tmp_local_jansi-native
jar cmf META-INF/MANIFEST.MF ../presto-cli-0.236-executable.jar  *
cd ..
cat $CWD/presto-cli-header.sh presto-cli-0.236-executable.jar > $PRESTODIR/presto-cli/target/presto-cli-0.236-executable.jar

cd $TMPDIR
rm -rf *
cd ..
rm -rf $TMPDIR
echo "===================================== Updated prest-cli jar =============================================="
