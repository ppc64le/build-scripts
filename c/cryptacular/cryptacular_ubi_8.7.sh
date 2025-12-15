#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cryptacular
# Version          : v1.2.6
# Source repo      : https://github.com/vt-middleware/cryptacular.git
# Tested on        : UBI 8.7
# Language         : Java
# Ci-Check     : True
# Script License   : GNU General Public License v3.0
# Maintainer       : Mohit Pawar <mohit.pawar@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#Variables
PACKAGE_NAME=cryptacular
PACKAGE_VERSION=v1.2.6
PACKAGE_URL=https://github.com/vt-middleware/cryptacular.git

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "PACKAGE_VERSION is an optional paramater whose default value is $PACKAGE_VERSION and building for ${1:-$PACKAGE_VERSION}"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

#install dependencies
yum update -y --allowerasing
yum install -y --allowerasing gcc gcc-c++ git sed unzip wget bzip2 yum-utils make cmake automake autoconf libtool gdb* binutils rpm-build gettext wget

yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/AppStream/ppc64le/os/
yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/PowerTools/ppc64le/os/
yum-config-manager --add-repo http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/

wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

# Install Python
yum install -y python3  python3-setuptools python3-devel  libevent-devel
#ln -s /usr/bin/python3.8 /usr/bin/python
#ln -s /usr/bin/pip3.8 /usr/bin/pip

# Installation of JAVA version 11
yum -y install java-11-openjdk java-11-openjdk-devel
# Installation of JAVAc version 11
export JAVA_HOME=export JAVA_HOME=/usr/lib/jvm/java-11-openjdk

HOME_DIR=`pwd`
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# Maven install
wget https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz
tar xzf apache-maven-3.8.8-bin.tar.gz
ln -s apache-maven-3.8.8 maven
export M2_HOME=$HOME_DIR/maven
export PATH=${M2_HOME}/bin:${PATH}
mvn -version

cd $HOME_DIR/

#Clone repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! mvn clean install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi 

if ! mvn test ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
