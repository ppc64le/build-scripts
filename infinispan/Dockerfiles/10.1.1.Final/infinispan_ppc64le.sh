#!/bin/bash
BUILD_HOME=`pwd`
BUILD_VERSION=10.1.1.Final
echo "`date +'%d-%m-%Y %T'` - Starting netty-tcnative build. Dependencies will be cloned in $BUILD_HOME"
# ------- Install dependencies -------
yum -y update
yum -y install subscription-manager.ppc64le
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
subscription-manager repos --enable rhel-7-for-power-le-extras-rpms
yum -y install epel-release
yum -y install gcc-c++.ppc64le
yum -y install wget git
yum install -y openssl-devel.ppc64le
yum install -y cmake.ppc64le cmake3.ppc64le
yum -y group install "Development Tools"
#Install jdk11
yum install -y java-11-openjdk java-11-openjdk-devel
yum -y install ninja-build-1.7.2-2.el7.ppc64le
yum -y install golang
yum -y install autoconf automake libtool make tar glibc-devel libaio-devel openssl-devel apr-devel lksctp-tools
yum -y install apr-devel apr-util-devel
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.6.10-0.el8_1.ppc64le
echo "`date +'%d-%m-%Y %T'` - JAVA_HOME $JAVA_HOME"
cd /usr/lib/jvm/
ls -l
echo "`date +'%d-%m-%Y %T'` - ...Here"
#Install maven
cd /
wget http://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzf apache-maven-3.6.3-bin.tar.gz
ln -s apache-maven-3.6.3 /maven
export M2_HOME=/maven
export PATH=${M2_HOME}/bin:${PATH}
mvn --version
cd /
echo "`date +'%d-%m-%Y %T'` - Building Infinispan -----------------------------------"
echo "- --------------------------------------------------------------------------------------"
cd $BUILD_HOME
#Copy the patch file
cd /
wget https://github.com/rashmi-ibm/build-scripts/blob/master/infinispan/Infini_fixes.patch
ls -l
pwd
git clone https://github.com/infinispan/infinispan
cd infinispan && git checkout $BUILD_VERSION
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./lucene/lucene-directory/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./server/memcached/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./tasks/scripting/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./counter/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./multimap/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./persistence/rocksdb/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./remote-query/remote-query-server/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./server/core/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./commons/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./jcache/embedded/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./query/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./core/pom.xml
sed -i 's/<goal>proto-schema-compatibility-check<\/goal>//g' ./server/runtime/pom.xml
mvn -s maven-settings.xml clean install -DskipTests=true
echo "`date +'%d-%m-%Y %T'` - Infinispan Complete -----------------------------------"
echo "- --------------------------------------------------------------------------------------"
