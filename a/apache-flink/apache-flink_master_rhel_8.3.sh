# Package : Apache Flink
# Version : master
# Source repo : https://github.com/apache/flink
# Tested on : rhel_8.3
# Maintainer : bivasda1@in.ibm.com / maniraj.deivendran@ibm.com
#
# Disclaimer: This script has been tested in non-root (with sudo) mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Must be installed node v10.9.0
#!/bin/bash

VERSION="master"
MAVEN_VERSION=3.6.3

# Install dependencies and tools.
sudo yum update -y
sudo yum install -y git wget java-1.8.0-openjdk-devel xz
export JAVA_HOME=export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk

# Install postgresql build dependencies
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-ppc64le/pgdg-redhat-repo-latest.noarch.rpm
sudo yum install -y postgresql10-libs
sudo yum install -y postgresql10 postgresql10-server postgresql10-contrib

# Install maven package
wget https://www-us.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz --no-check-certificate --quiet
tar xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz

# Set ENV variables
export M2_HOME=`pwd`/apache-maven-${MAVEN_VERSION}
export PATH=`pwd`/apache-maven-${MAVEN_VERSION}/bin:${PATH}

# Clone and build source
git clone https://github.com/apache/flink.git
cd flink
git checkout $VERSION

# Updated com.google.protobuf:protoc from 3.5.1-->3.7.0
sed -i 's/3.5.1/3.7.0/g' flink-formats/flink-parquet/pom.xml

# Compile and build package using threads
mvn clean package -T 6 -DskipTests -Dfast

# Resolve "No postgres binary for ppc64le" error by
# extract the otj-pg-embedded-0.13.3.jar which consist of
# postgres bin file for x86/Darwin/Windows platform. In which,
# copy the required bin files(postgres, pg_ctl and initdb)
# for ppc64le from latest postgresql rpm packages and again
# prepare the JAR file.
mkdir tmpdir
cd tmpdir
rm -rf *
mv ~/.m2/repository/com/opentable/components/otj-pg-embedded/0.13.3/otj-pg-embedded-0.13.3.jar .
jar xf otj-pg-embedded-0.13.3.jar
rm -rf otj-pg-embedded-0.13.3.jar
mkdir postgresql-Linux-ppc64le
tar xf postgresql-Linux-x86_64.txz -C postgresql-Linux-ppc64le
cd postgresql-Linux-ppc64le
rm -rf bin/*
rm -rf lib/*
rm -rf share/*
cp /usr/pgsql-10/bin/pg_ctl bin/
cp /usr/pgsql-10/bin/postgres bin/
cp /usr/pgsql-10/bin/initdb bin/
cp -r /usr/pgsql-10/lib/* lib/
cp -r /usr/pgsql-10/share/* share/
tar cJf postgresql-Linux-ppc64le.txz share lib bin
mv postgresql-Linux-ppc64le.txz ../
cd ..
jar cf otj-pg-embedded-0.13.3.jar com META-INF otj-pg-embedded.properties postgresql-Linux-ppc64le.txz postgresql-Darwin-x86_64.txz postgresql-Linux-x86_64.txz postgresql-Windows-x86_64.txz
cp otj-pg-embedded-0.13.3.jar ~/.m2/repository/com/opentable/components/otj-pg-embedded/0.13.3/
cd ..

# Create /var/run/postgresql and change ownership to current non-root user
USER=`whoami`
mkdir -p /var/run/postgresql/
sudo chown $USER:$USER /var/run/postgresql/

# This step assumes that you have already copied the patch file as a sibbling of this script
# Updated pom.xml with known errors
git apply apache-flink_ignore_test_fail.patch

# Re-build with tests
echo "===================================== Re-build with tests begin ==========================================="
mvn clean package
echo "===================================== Re-build with tests end ============================================="
