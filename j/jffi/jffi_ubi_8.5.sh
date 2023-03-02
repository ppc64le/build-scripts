#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : jffi
# Version       : jffi-1.3.10
# Source repo   : https://github.com/JodaOrg/joda-time
# Tested on     : UBI 8.5
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=jffi
PACKAGE_URL=https://github.com/jnr/jffi
PACKAGE_VERSION={1:-jffi-1.3.10}

yum install -y git make wget gcc-c++ java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

cat > /etc/yum.repos.d/centos.repo<<EOF
[local-rhn-server-baseos]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server RPMs
baseurl=http://mirror.centos.org/centos/8-stream/BaseOS/\$basearch/os/
enabled=1
gpgcheck=0
[local-rhn-server-appstream]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server Supplementary RPMs
baseurl=http://mirror.centos.org/centos/8-stream/AppStream/\$basearch/os/
enabled=1
gpgcheck=0
[local-rhn-server-powertools]
name=Poughkeepsie Client Center Local RHN - RHEL \$releasever \$basearch Server Supplementary RPMs
baseurl=http://mirror.centos.org/centos/8-stream/PowerTools/\$basearch/os/
enabled=1
gpgcheck=0
EOF

yum install -y texinfo

wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz
tar -zxf apache-maven-3.8.7-bin.tar.gz
cp -R apache-maven-3.8.7 /usr/local
ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn

wget https://downloads.apache.org/ant/binaries/apache-ant-1.10.13-bin.tar.gz
tar -xvf apache-ant-1.10.13-bin.tar.gz
mv apache-ant-1.10.13 /opt/ant
export ANT_HOME=/opt/ant
export PATH=$PATH:$ANT_HOME/bin

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! mvn clean install ; then
    echo "------------------$PACKAGE_NAME:Build_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! ant test ; then
    echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi




