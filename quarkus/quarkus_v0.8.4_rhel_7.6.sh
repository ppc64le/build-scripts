# ----------------------------------------------------------------------------
#
# Package       : quarkus
# Version       : v0.8.4
# Source repo   : https://github.com/quarkusio/quarkus
# Tested on     : Linux p006n04 3.10.0-1062.el7.ppc64le 
# Script License: Apache License, Version 2 or later
# Maintainer    : Rashmi Sakhalkar <srashmi@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

yum update -y
yum install java-1.8.0-openjdk-devel wget git -y
yum install cyrus-sasl cyrus-sasl-gssapi cyrus-sasl-plain krb5-libs libcurl libpcap lm_sensors-libs -y
yum install net-snmp net-snmp-agent-libs openldap openssl rpm-libs -y
yum install tcp_wrappers-libs -y

#Setup maven
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.2/binaries/apache-maven-3.6.2-bin.tar.gz
tar xzf apache-maven-3.6.2-bin.tar.gz
ln -s apache-maven-3.6.2 /maven
export M2_HOME=/maven
export PATH=${M2_HOME}/bin:${PATH}

mv /opt/mongodb/linux/mongodb-linux-ppc64le-enterprise-rhel71-4.0.12.tgz /opt/mongodb/linux/mongodb-linux-ppc64le-4.0.12.tgz

#Build de.flapdoodle.embed.process jar
git clone https://github.com/flapdoodle-oss/de.flapdoodle.embed.process
cd de.flapdoodle.embed.process/ && git checkout de.flapdoodle.embed.process-2.1.2
git apply ../processFix.patch
./mvnw clean install && cd ..

#Build de.flapdoodle.embed.mongo jar
git clone https://github.com/flapdoodle-oss/de.flapdoodle.embed.mongo
cd de.flapdoodle.embed.mongo && git checkout de.flapdoodle.embed.mongo-2.2.0
git apply ../mongoFix1.patch
./mvnw clean install -DskipTests && cd ..

#Build quarkus
git clone https://github.com/quarkusio/quarkus
cd quarkus && git checkout 0.24.0
git apply ../quarkus.patch
./mvnw clean install