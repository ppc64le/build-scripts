# ----------------------------------------------------------------------------
#
# Package	: glassfish
# Version	: 4.1
# Source repo	: http://download.java.net/glassfish/4.1/release
# Tested on	: rhel_7.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Atul Sowani <sowania@us.ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

# Install dependencies.
sudo yum update -y
sudo yum install -y git wget unzip curl java-1.8.0-openjdk \
    java-1.8.0-openjdk-devel

# Set up environment.
export PKG_FILE_NAME=glassfish-4.1.zip
export GLASSFISH_PKG=http://download.java.net/glassfish/4.1/release/$PKG_FILE_NAME
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk
export CONFIG_JVM_ARGS=-Djava.security.egd=file:/dev/./urandom

# Download Glassfish 4.1 JAR.
mkdir /tmp/glassfish
cd /tmp/glassfish
wget $GLASSFISH_PKG
unzip glassfish-4.1.zip
rm $PKG_FILE_NAME
sed -i 's/-client/-server/' /tmp/glassfish/glassfish4/glassfish/domains/domain1/config/domain.xml
echo "admin;{SSHA256}80e0NeB6XBWXsIPa7pT54D9JZ5DR5hGQV1kN1OAsgJePNXY6Pl0EIw==;asadmin" > /tmp/glassfish/glassfish4/glassfish/domains/domain1/config/admin-keyfile
echo "AS_ADMIN_PASSWORD=glassfish" > pwdfile
echo "export PATH=$PATH:/tmp/glassfish/glassfish4/bin" >> /tmp/glassfish/.bashrc
sudo useradd -b /tmp -m -s /bin/bash glassfish
echo glassfish:glassfish | sudo chpasswd
sudo chown -R glassfish:glassfish /tmp/glassfish
