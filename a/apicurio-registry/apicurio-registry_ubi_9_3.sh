
#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : apicurio-registry
# Version       : 2.5.10.Final
# Source repo   : https://github.com/Apicurio/apicurio-registry
# Tested on     : UBI 9.3
# Language      : Java
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e
PACKAGE_NAME=apicurio-registry
PACKAGE_VERSION=${1:-2.5.10.Final}
PACKAGE_URL=https://github.com/Apicurio/apicurio-registry

HOME_DIR=${PWD}

yum install -y wget yum-utils

dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

yum install -y git java-17-openjdk-devel wget make 
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-17)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH
java --version

#installing maven 
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.6-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.6-bin.tar.gz
mv /usr/local/apache-maven-3.8.6 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin
mvn --version

#installing go
wget https://go.dev/dl/go1.22.1.linux-ppc64le.tar.gz
tar -C  /usr/local -xf go1.22.1.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go 
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
go version

#kiota
git clone https://github.com/microsoft/kiota.git
cd kiota
dnf install -y https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
dnf install -y dotnet-sdk-8.0
dotnet build src/kiota/kiota.csproj -c Release /p:SignAssembly=false
chmod +x ${HOME_DIR}/kiota/src/kiota/bin/Release/net8.0/kiota
export PATH=$PATH:${HOME_DIR}/kiota/src/kiota/bin/Release/net8.0

echo ${HOME_DIR}/kiota/src/kiota/bin/Release/net8.0
kiota --version
cd ..

# Cloning the repository 
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


#java-sdk
sed -i '/<\/properties>/i \    <kiota.local.path>/kiota/src/kiota/bin/Release/net8.0/kiota</kiota.local.path>' ${HOME_DIR}/apicurio-registry/java-sdk/pom.xml
sed -i '0,/<configuration>/s|<configuration>|\0\n          <kiotaPath>${kiota.local.path}</kiotaPath>\n          <logLevel>Debug</logLevel>\n          <useSystemKiota>true</useSystemKiota>|' ${HOME_DIR}/apicurio-registry/java-sdk/pom.xml

#java-sdk-v2
sed -i '/<\/properties>/i \    <kiota.local.path>/kiota/src/kiota/bin/Release/net8.0/kiota</kiota.local.path>' ${HOME_DIR}/apicurio-registry/java-sdk-v2/pom.xml
sed -i '0,/<configuration>/s|<configuration>|\0\n              <kiotaPath>${kiota.local.path}</kiotaPath>\n              <logLevel>Debug</logLevel>\n              <useSystemKiota>true</useSystemKiota>|' ${HOME_DIR}/apicurio-registry/java-sdk-v2/pom.xml

#go-sdk
sed -i '/if \[\[ ! -f \$SCRIPT_DIR\/target\/kiota_tmp\/kiota \]\]/,/# fi/s|curl -sL \$URL > \$SCRIPT_DIR/target/kiota_tmp/kiota.zip|cp -r /kiota/src/kiota/bin/Release/net8.0/* \$SCRIPT_DIR/target/kiota_tmp/|' ${HOME_DIR}/apicurio-registry/go-sdk/generate.sh

#pom.xml
sed -i 's|<phase>generate-resources</phase>|<phase>package</phase>|' ${HOME_DIR}/apicurio-registry/app/pom.xml

if ! mvn install -DskipTests=true ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Skipping App tests as those are in parity with intel
if ! mvn test -DskipAppTests=true ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

