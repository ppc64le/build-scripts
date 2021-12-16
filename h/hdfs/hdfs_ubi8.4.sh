# -----------------------------------------------------------------------------
#
# Package       : github.com/colinmarc/hdfs/v2
# Version       : v2.2.0
# Source repo   : https://github.com/colinmarc/hdfs
# Tested on     : RHEL 8.4
# Script License: Apache License, Version 2 or later
# Maintainer    : Vikas Gupta <vikas.gupta8@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#
PACKAGE_NAME=hdfs
PACKAGE_PATH=github.com/colinmarc/hdfs/v2
PACKAGE_VERSION=${1:-v2.2.0}
PACKAGE_URL=https://github.com/colinmarc/hdfs

yum install -y git wget make gcc
yum install -y autoconf automake libtool curl unzip bzip2
yum install -y gcc gcc-c++
yum install -y psmisc nc openssl-devel maven hostname initscripts redhat-lsb-core

wget https://golang.org/dl/go1.17.4.linux-ppc64le.tar.gz && tar -C /bin -xf go1.17.4.linux-ppc64le.tar.gz && mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg

mkdir -p /home/tester/output
export HOME_DIR=/home/tester

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go

export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

cd $HOME_DIR

echo "-------------Installing protobuff version ---------------------"

git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
./autogen.sh

./configure
make
make install
ldconfig

#----------------------------------------------------------------------------------------
echo "-------------Installing hadoop and its dependencies ---------------------"
cd $HOME_DIR

wget --no-check-certificate https://ci.bigtop.apache.org/job/Bigtop-trunk-packages/COMPONENTS=bigtop-utils,OS=centos-8-ppc64le/lastSuccessfulBuild/artifact/output/bigtop-utils/noarch/bigtop-utils-3.1.0-1.el8.noarch.rpm && rpm -ivh bigtop-utils-3.1.0-1.el8.noarch.rpm

wget https://copr-be.cloud.fedoraproject.org/results/harbottle/main/epel-8-x86_64/02183367-zookeeper/zookeeper-3.7.0-2.el8.harbottle.noarch.rpm && rpm -ivh zookeeper-3.7.0-2.el8.harbottle.noarch.rpm

wget --no-check-certificate https://ci.bigtop.apache.org/job/Bigtop-trunk-packages/COMPONENTS=hadoop,OS=centos-8-ppc64le/lastSuccessfulBuild/artifact/output/hadoop/ppc64le/hadoop-3.2.2-1.el8.ppc64le.rpm && rpm -ivh hadoop-3.2.2-1.el8.ppc64le.rpm

wget --no-check-certificate https://ci.bigtop.apache.org/job/Bigtop-trunk-packages/COMPONENTS=bigtop-groovy,OS=centos-8-ppc64le/lastSuccessfulBuild/artifact/output/bigtop-groovy/noarch/bigtop-groovy-2.5.4-1.el8.noarch.rpm && rpm -ivh bigtop-groovy-2.5.4-1.el8.noarch.rpm

wget --no-check-certificate https://ci.bigtop.apache.org/job/Bigtop-trunk-packages/COMPONENTS=bigtop-jsvc,OS=centos-8-ppc64le/lastSuccessfulBuild/artifact/output/bigtop-jsvc/ppc64le/bigtop-jsvc-1.0.15-1.el8.ppc64le.rpm && rpm -ivh bigtop-jsvc-1.0.15-1.el8.ppc64le.rpm

wget  --no-check-certificate https://ci.bigtop.apache.org/job/Bigtop-trunk-packages/COMPONENTS=hadoop,OS=centos-8-ppc64le/757/artifact/output/hadoop/ppc64le/hadoop-hdfs-3.2.2-1.el8.ppc64le.rpm && rpm -ivh hadoop-hdfs-3.2.2-1.el8.ppc64le.rpm
#----------------------------------------------------------------------------------------

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

HADOOP_FS=${HADOOP_FS-"hadoop fs"}
$HADOOP_FS -mkdir -p "/_test"
$HADOOP_FS -chmod 777 "/_test"

$HADOOP_FS -put ./testdata/foo.txt "/_test/foo.txt"
$HADOOP_FS -Ddfs.block.size=1048576 -put ./testdata/mobydick.txt "/_test/mobydick.txt"

#----------------------------------------------------------------------------------------
echo "-------------Installing bats ---------------------"
cd $HOME_DIR

git clone https://github.com/sstephenson/bats
cd bats
mkdir build
$HOME/bats/install.sh $HOME/bats/build
export PATH="$PATH:$HOME/bats/build/bin"

#----------------------------------------------------------------------------------------
echo "-------------Installing and testing hdfs ---------------------"
cd $HOME_DIR

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"

if ! go get -d -u -t $PACKAGE_PATH@$PACKAGE_VERSION; then
        echo "------------------$PACKAGE_NAME:install_ failed-------------------------"
        exit 0
fi

cd $(ls -d $GOPATH/pkg/mod/$PACKAGE_PATH@$PACKAGE_VERSION/)

echo `pwd`

# Ensure go.mod file exists
go mod init $PACKAGE_PATH
go mod tidy

make clean
make clean-protos


if ! make hdfs; then
        echo "------------------$PACKAGE_NAME: build failed retrying-------------------------"
	cp -rf internal/protocol/hadoop_common/github.com/colinmarc/hdfs/v2/internal/protocol/hadoop_common/Security.pb.go internal/protocol/hadoop_common/
	if ! make hdfs; then
        	echo "------------------$PACKAGE_NAME: build failed -------------------------"
        	exit 0
	fi
fi

if ! make test; then
        echo "------------------$PACKAGE_NAME: make test failed-------------------------"
	if ! go test -v ./...; then
		echo "------------------$PACKAGE_NAME: go test failed-------------------------"
		exit 0
	else
        	echo "------------------$PACKAGE_NAME: go test success-------------------------"
	fi
	
	if ! bats ./cmd/hdfs/test/*.bats; then
		echo "------------------$PACKAGE_NAME: bat test failed-------------------------"
		exit 0
	else
        	echo "------------------$PACKAGE_NAME: go and bat test success-------------------------"
        	echo "------------------$PACKAGE_NAME: install, build and test success-------------------------"
	fi
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi

cd $HOME_DIR

