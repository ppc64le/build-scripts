# ----------------------------------------------------------------------------
#
# Package        : apache-tomcat
# Version        : 10.0.6
# Source repo    : https://github.com/apache/tomcat.git
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

#Install JAVA
yum install -y java java-devel
whichJavaString=$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-1.8)(?=.*ppc64le)')

# Set JAVA_HOME variable 
export JAVA_HOME=/usr/lib/jvm/$whichJavaString
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

mkdir temp_dir
cd temp_dir
#Clone repo
git clone https://github.com/apache/tomcat.git
cd tomcat
git checkout tags/10.0.6

#Build the Package
ant
#Test the Package (It may take More then 3 hours)
ant test
