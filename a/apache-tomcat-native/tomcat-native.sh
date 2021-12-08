# ----------------------------------------------------------------------------
#
# Package        : tomcat-native
# Version        : 1.2.28
# Source repo    : https://github.com/apache/tomcat-native.git
# Tested on      : ubi:8.3
# Script License : Apache License 2.0
# Maintainer     : Anant Pednekar <Anant.Pednekar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
#Update Repos
#yum -y update

#Install Utilities
yum install -y git

# install Java
yum install -y java java-devel
whichJavaString=$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-1.8)(?=.*ppc64le)')
# Set JAVA_HOME variable 
export JAVA_HOME=/usr/lib/jvm/$whichJavaString
whichJavaString=$(ls /usr/lib/jvm/ | grep -P '^(?=.*jre-1.8)(?=.*ppc64le)')
export JRE_HOME=/usr/lib/jvm/$whichJavaString
# update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin

#Install ANT
yum install -y wget
wget https://downloads.apache.org/ant/binaries/apache-ant-1.10.9-bin.tar.gz
tar -xf apache-ant-1.10.9-bin.tar.gz
# Set ANT_HOME variable 
export ANT_HOME=${pwd}/apache-ant-1.10.9
# update the path env. variable 
export PATH=${PATH}:${ANT_HOME}/bin

#Clone repo
git clone https://github.com/apache/tomcat-native.git
cd tomcat-native
git checkout tags/1.2.28

#Build the Package
ant

#download and copytesting libs
ant download
cp -a  /usr/share/java/.  ${ANT_HOME}/lib/

#Test the Package
ant test
