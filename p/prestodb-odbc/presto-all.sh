#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

echo "===================================== dep installs ==========================================="
apt-get -y update
apt-get install -y git gcc g++ make cmake bison build-essential \
        libncurses5-dev wget gzip tar python ant unzip libghc-zlib-dev zlibc \
        openjdk-8-jdk openjdk-8-jre automake autoconf mysql-server \
        snappy libsnappy-dev libsnappy-java libsnappy-jni openssl maven

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:$JAVA_HOME/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib

echo "===================================== presto cloned ==========================================="
WDIR=`pwd`
git clone https://github.com/prestodb/presto.git

echo "===================================== protobuf, hadoop install ==========================================="
# Install ProtoBuf
mkdir /root/hadoopCode
cd /root/hadoopCode
git clone https://github.com/ibmsoe/Protobuf.git && \
    cd /root/hadoopCode/Protobuf && ./configure && \
    make && make check && make install && \
    echo "export HADOOP_PROTOC_PATH=/usr/local/bin/protoc" >> ~/.bash_profile
export HADOOP_PROTOC_PATH=/usr/local/bin/protoc

# Install Hadoop
cd /root/hadoopCode
git clone https://github.com/ibmsoe/hadoop.git
cd /root/hadoopCode/hadoop/hadoop-common-project/hadoop-common/
git checkout origin/branch-2.6.0

mvn -e -l mvn.Compile.res clean compile -Pdist,native,src -DskipTests -Drequire.snappy -X
mvn -l mvn.Compile.res compile -Pdist,native,src -DskipTests -Drequire.snappy -X
mvn -l mvn.Install.res install -Pnative,src -DskipTests -Drequire.snappy -X
mvn package -Pnative,dist -DskipTests -Dtar -X
## ------------------------- hadoop install over ---------------------------------

echo "===================================== compo build test start ==========================================="
cd $WDIR
cd presto
echo "=====presto-atop======" && cd presto-atop && mvn test
echo "=====presto-spi======" && cd ../presto-spi && mvn test
echo "=====presto-jmx======" && cd ../presto-jmx && mvn test
echo "=====presto-record-decoder======" && cd ../presto-record-decoder && mvn test
echo "=====presto-kafka======" && cd ../presto-kafka && mvn test
echo "=====presto-redis======" && cd ../presto-redis && mvn test -DskipTests
echo "=====presto-cassandra======" && cd ../presto-cassandra && mvn test
echo "=====presto-blackhole======" && cd ../presto-blackhole && mvn test
echo "=====presto-orc======" && cd ../presto-orc && mvn test
echo "=====presto-hive======" && cd ../presto-hive && mvn test
echo "=====presto-hive-hadoop1======" && cd ../presto-hive-hadoop1 && mvn test
echo "=====presto-hive-hadoop2======"  && cd ../presto-hive-hadoop2 && mvn test
echo "=====presto-hive-cdh4======"  && cd ../presto-hive-cdh4 && mvn test
echo "=====presto-hive-cdh5======"  && cd ../presto-hive-cdh5 && mvn test
echo "=====presto-teradata-functions======" && cd ../presto-teradata-functions && mvn test
echo "=====presto-example-http======" && cd ../presto-example-http && mvn test
echo "=====presto-local-file======" && cd ../presto-local-file && mvn test
echo "=====presto-tpch======" && cd ../presto-tpch && mvn test
echo "=====presto-raptor======" && cd ../presto-raptor && mvn test -DskipTests
echo "=====presto-base-jdbc======" && cd ../presto-base-jdbc && mvn test
echo "=====presto-mysql======" && cd ../presto-mysql && mvn test -DskipTests
echo "=====presto-postgresql======"  && cd ../presto-postgresql && mvn test -DskipTests
echo "=====presto-mongodb======" && cd ../presto-mongodb && mvn test
echo "=====presto-bytecode======" && cd ../presto-bytecode && mvn test
echo "=====presto-client======" && cd ../presto-client && mvn test
echo "=====presto-parser======" && cd ../presto-parser && mvn test
echo "=====presto-main======" && cd ../presto-main && mvn test -DskipTests
echo "=====presto-ml======" && cd ../presto-ml && mvn test
echo "=====presto-benchmark======" && cd ../presto-benchmark && mvn test
echo "=====presto-tests======" && cd ../presto-tests && mvn test
echo "=====presto-product-tests======" && cd ../presto-product-tests && mvn test
echo "=====presto-jdbc======" && cd ../presto-jdbc && mvn test
echo "=====presto-cli======" && cd ../presto-cli && mvn test
echo "=====presto-benchmark-driver======" && cd ../presto-benchmark-driver && mvn test
echo "=====presto-server======" && cd ../presto-server && mvn test
echo "=====presto-server-rpm======" && cd ../presto-server-rpm && mvn test
echo "=====presto-verifier======" && cd ../presto-verifier && mvn test
echo "=====presto-testing-server-launcher======" && cd ../presto-testing-server-launcher && mvn test