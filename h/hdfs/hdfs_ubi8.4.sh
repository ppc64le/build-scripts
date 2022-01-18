#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : github.com/colinmarc/hdfs/v2
# Version       : v2.2.0
# Source repo   : https://github.com/colinmarc/hdfs
# Tested on     : RHEL 8.4
# Script License: Apache License, Version 2 or later
# Language      : GO
# Travis-Check  : True
# Maintainer    : Vikas Gupta <vikas.gupta8@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

PACKAGE_NAME=hdfs
PACKAGE_PATH=github.com/colinmarc/hdfs/v2
PACKAGE_VERSION=${1:-v2.2.0}
PACKAGE_URL=https://github.com/colinmarc/hdfs

yum install -y curl unzip bzip2 gcc-c++ cmake
yum install -y psmisc nc openssl-devel maven hostname initscripts redhat-lsb-core
yum install -y make maven git sudo wget apr-devel perl openssl-devel automake autoconf libtool

wget https://downloads.apache.org/bigtop/bigtop-3.0.0/repos/GPG-KEY-bigtop
rpm --import GPG-KEY-bigtop
rm -rf GPG-KEY-bigtop
sudo wget -O /etc/yum.repos.d/bigtop.repo https://downloads.apache.org/bigtop/bigtop-3.0.0/repos/centos-8/bigtop.repo
sudo yum install -y hadoop hadoop-client bigtop-utils zookeeper

wget https://golang.org/dl/go1.17.4.linux-ppc64le.tar.gz && tar -C /bin -xf go1.17.4.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

mkdir -p /home/tester/output
export HOME_DIR=/home/tester

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

cp -rf ./protobuf_v2.5.0.patch $HOME_DIR
cd $HOME_DIR

#----------------------------------------------------------------------------------------
echo "-------------Installing protobuff version v2.5.0---------------------"
#Install latest cmake
#wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2.tar.gz
#tar -xvf cmake-3.21.2.tar.gz
#cd cmake-3.21.2
#./bootstrap
#make
#make install
#cd ..

cd $HOME_DIR
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout v2.5.0
git apply ../protobuf_v2.5.0.patch
./autogen.sh
./configure
make
make install
cd java
mvn clean install

echo "-------------Setting Environment Variables ---------------------"
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-2.el8_5.ppc64le/
#export HADOOP_HOME="/etc/hadoop"
export HADOOP_HOME=/usr/lib/hadoop
export HADOOP_CONF_DIR="/etc/hadoop/conf"

tee /etc/hadoop/conf/core-site.xml <<EOF
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
  </property>
</configuration>
EOF

tee /etc/hadoop/conf/hdfs-site.xml <<EOF
<configuration>
  <property>
    <name>dfs.namenode.name.dir</name>
    <value>/opt/hdfs/name</value>
  </property>
  <property>
    <name>dfs.datanode.data.dir</name>
    <value>/opt/hdfs/data</value>
  </property>
  <property>
   <name>dfs.permissions.superusergroup</name>
   <value>hadoop</value>
  </property>
</configuration>
EOF

mkdir -p /opt/hdfs/data /opt/hdfs/name
chown -R hdfs:hdfs /opt/hdfs
hdfs namenode -format -nonInteractive

/usr/lib/hadoop/sbin/hadoop-daemon.sh start datanode
/usr/lib/hadoop/sbin/hadoop-daemon.sh start namenode

#----------------------------------------------------------------------------------------
echo "-------------Installing bats ---------------------"
cd $HOME_DIR

git clone https://github.com/sstephenson/bats
cd bats
mkdir build
$HOME_DIR/bats/install.sh $HOME/bats/build
export PATH="$PATH:$HOME/bats/build/bin"

#----------------------------------------------------------------------------------------
echo "-------------Installing and testing hdfs ---------------------"
cd $HOME_DIR

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"

if ! git clone --recurse $PACKAGE_URL; then
        echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
        exit 1
fi

#cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_PATH@$PACKAGE_VERSION/)
cd $PACKAGE_NAME
echo `pwd`

git checkout $PACKAGE_VERSION

# Ensure go.mod file exists
#go mod init $PACKAGE_PATH
#go mod tidy
#go get ./...

make clean
make clean-protos

go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.22.0
go get google.golang.org/protobuf/reflect/protoreflect
#go mod tidy
export PATH=$GOPATH/bin:$PATH

sed -i '/^export JAVA_HOME/d' fixtures.sh
sed -i '/^export JAVA_HOME/d' cmd/hdfs/test/helper.bash

if ! make hdfs; then
        echo "------------------$PACKAGE_NAME: build failed retrying-------------------------"
	cp -rf internal/protocol/hadoop_common/github.com/colinmarc/hdfs/v2/internal/protocol/hadoop_common/Security.pb.go internal/protocol/hadoop_common/
	if ! make hdfs; then
        	echo "------------------$PACKAGE_NAME: build failed -------------------------"
        	exit 0
	fi
fi

HADOOP_FS=${HADOOP_FS-"hadoop fs"}
$HADOOP_FS -mkdir -p "/_test"
$HADOOP_FS -chmod 777 "/_test"

$HADOOP_FS -put ./testdata/foo.txt "/_test/foo.txt"
$HADOOP_FS -Ddfs.block.size=1048576 -put ./testdata/mobydick.txt "/_test/mobydick.txt"

echo "------------------$PACKAGE_NAME: running go test-------------------------"
if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME: go test failed-------------------------"
	exit 0
else
       	echo "------------------$PACKAGE_NAME: go test success-------------------------"
fi

echo "------------------$PACKAGE_NAME: running bat test-------------------------"
if ! bats ./cmd/hdfs/test/*.bats; then
	echo "------------------$PACKAGE_NAME: bat test failed-------------------------"
	exit 0
else
       	echo "------------------$PACKAGE_NAME: go and bat test success-------------------------"
       	echo "------------------$PACKAGE_NAME: install, build and test success-------------------------"
fi

cd $HOME_DIR

