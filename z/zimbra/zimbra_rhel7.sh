# ----------------------------------------------------------------------------
#
# Package	: Zimbra
# Version	: 9.0.0-7-g0c716
# Source repo	: https://github.com/Zimbra/zm-build.git
# Tested on	: rhel_7.8
# Script License: Apache License, Version 2 or later
# Maintainer	: Kandarpa Malipeddi <Kandarpa.Malipeddi@ibm.com>
#
# Disclaimer	: This script has been tested in root mode on given
# ==========  	platform using the mentioned version of the package.
#             	It may not work as expected with newer versions of the
#             	package and/or distribution. In such case, please
#             	contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash -e

BUILD_HOME=$PWD

yum update -y && yum install -y createrepo rpm-build gcc-c++ git make java-1.8.0-openjdk java-1.8.0-openjdk-devel ruby git cpan wget perl-IPC-Cmd rsync m4 pcre-devel sudo perl perl-core popt-devel zlib-devel openssl-devel bzip2-devel hg ncurses-devel expat-devel libaio-devel cmake perl-libwww-perl libtool libidn-devel perl-Test-Deep perl-Test-Inter  perl-Net-DNS perl-Crypt-OpenSSL-RSA perl-MailTools perl-Test-RequiresInternet  perl-YAML-LibYAML perl-Test-Warn

##############################
# Download the maven
##############################
cd /opt
wget https://downloads.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzf apache-maven-3.6.3-bin.tar.gz
ln -s apache-maven-3.6.3 maven
export M2_HOME=/opt/maven

echo "
export PATH=${M2_HOME}/bin:${PATH}
" > /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh

##############################
# Download the ant
##############################

cd /opt
wget http://apachemirror.wuchna.com//ant/binaries/apache-ant-1.9.15-bin.tar.gz
tar xzf apache-ant-1.9.15-bin.tar.gz
ln -s apache-ant-1.9.15 ant

echo "
export PATH=/opt/ant/bin:${PATH}
" > /etc/profile.d/ant.sh
source /etc/profile.d/ant.sh


############################
# Downloading  ZCS
############################
mkdir -p ${BUILD_HOME}/installer-build
cd $BUILD_HOME/installer-build
git clone https://github.com/Zimbra/zm-build.git
cd zm-build
git checkout origin/develop

######################################
# Generate build details
######################################
PLATFORM_TAG=`./rpmconf/Build/get_plat_tag.sh`
BUILD_RELEASE=JUDASPRIEST
BUILD_RELEASE_NO=9.0.0
BUILD_RELEASE_NO_SHORT=`echo $BUILD_RELEASE_NO | sed "s/\.//g"`
BUILD_TS=`date +'%Y%m%d%H%M%S'`
BUILD_TYPE=FOSS
BUILD_NO=2020
BUILD_RELEASE_CANDIDATE=GA

BUILD_OUT_DIR=`echo "$PLATFORM_TAG-$BUILD_RELEASE-$BUILD_RELEASE_NO_SHORT-$BUILD_TS-$BUILD_TYPE-$BUILD_NO"`

echo "
BUILD_NO                = $BUILD_NO
BUILD_TS                = $BUILD_TS
BUILD_RELEASE           = $BUILD_RELEASE
BUILD_RELEASE_NO        = $BUILD_RELEASE_NO
BUILD_RELEASE_CANDIDATE = $BUILD_RELEASE_CANDIDATE
BUILD_TYPE              = $BUILD_TYPE
BUILD_THIRDPARTY_SERVER = files.zimbra.com
BUILD_ARCH              = ppc64le

 %GIT_OVERRIDES          = myremote.url-prefix=https://github.com/Zimbra
" > config.build

if [ "${buildType}" = "NETWORK" ]
then
   ZCS_REL=zcs-${BUILD_TYPE}-${BUILD_RELEASE_NO}_${BUILD_RELEASE_CANDIDATE}_${BUILD_NO}.${PLATFORM_TAG}.${BUILD_TS}
else
   ZCS_REL=zcs-${BUILD_RELEASE_NO}_${BUILD_RELEASE_CANDIDATE}_${BUILD_NO}.${PLATFORM_TAG}.${BUILD_TS}
fi

if [ `echo $PLATFORM_TAG | grep "UBUNTU"` ]
then
	OS_TAG=`echo $PLATFORM_TAG | sed "s/UBUNTU\([0-9]*\).*/u\1/g"`
else
	OS_TAG=`echo $PLATFORM_TAG | sed "s/RHEL\([0-9]*\).*/r\1/g"`
fi


REPO_DIR=${BUILD_HOME}/installer-build/.staging/${BUILD_OUT_DIR}/zm-packages/bundle/${OS_TAG}

######################################
# Creating a local repo.
######################################

mkdir -p ${REPO_DIR}
cd $REPO_DIR
createrepo .

echo "
[local-zimbra]
name=Zimbra repo for Zimbra packages
baseurl=file://${REPO_DIR}
enabled=1
gpgcheck=0" > /etc/yum.repos.d/local_zimbra.repo

yum update -y

##############################################
# This function updates the local repo.
# Call it after each 3rd party pacakge built.
##############################################
updaterepo()
{
	cd ${REPO_DIR}; createrepo .; yum clean all; yum repolist enabled;cd -;
}


########################################
# Downloading third-party packages for Zimbra
########################################
cd $BUILD_HOME/installer-build

git clone https://github.com/Zimbra/zimbra-package-stub.git
git clone https://github.com/Zimbra/packages.git
cd packages

##############################
# Applying patches for all packages
##############################
git apply ${BUILD_HOME}/zimbra_packages.patch
touch /usr/include/stropts.h


for comp in `cat build-order | grep -v "^ "`
do
		if [ `echo "$comp" | grep "perl-net-ssleay"` ]
        then
                yum install -y openssl-devel
        fi

        cd $comp
        make all
        cp -v `find -name *.ppc64le.rpm` ${REPO_DIR}/
		
        cd ../../
        updaterepo
done

cd thirdparty/jetty-distribution/
make all
cp -v `find -name *.rpm` ${REPO_DIR}/


############################
# Applying zm-build patch
############################
cd $BUILD_HOME/installer-build/zm-build
git apply ${BUILD_HOME}/zm-build.patch

############################
# Applying patch for junixsocket
############################
cd $BUILD_HOME/installer-build/
git clone --branch junixsocket-parent-2.0.4 https://github.com/kohlschutter/junixsocket.git
cd junixsocket
git apply ${BUILD_HOME}/junixsocket.patch

############################
# Applying patch for zm-mailbox
############################
cd $BUILD_HOME/installer-build/
git clone https://github.com/Zimbra/zm-mailbox.git
cd zm-mailbox
git apply ${BUILD_HOME}/zm-mailbox.patch

############################
# Applying patch for zm-jython
############################
cd $BUILD_HOME/installer-build/
git clone https://github.com/Zimbra/zm-jython.git
cd zm-jython
git apply ${BUILD_HOME}/zm-jython.patch


############################
# Applying patch for zm-zcs-libs 
############################
cd $BUILD_HOME/installer-build/
git clone https://github.com/Zimbra/zm-zcs-lib.git
cd zm-zcs-lib
git apply ${BUILD_HOME}/zm-zcs-lib.patch

mkdir -p ${BUILD_HOME}/installer-build/.staging/${BUILD_OUT_DIR}/zm-zcs-lib/build/stage/zimbra-common-core-libs/opt/zimbra/lib/jars
ZCS_PATH=$PWD
mkdir -p /tmp/zimbra/syslog4j
cd /tmp/zimbra/syslog4j
git clone https://github.com/graylog-labs/syslog4j-graylog2.git
cd syslog4j-graylog2
mvn clean package
cp target/syslog4j-0.9.61-SNAPSHOT.jar ${BUILD_HOME}/installer-build/.staging/${BUILD_OUT_DIR}/zm-zcs-lib/build/stage/zimbra-common-core-libs/opt/zimbra/lib/jars


############################
# Building ZCS
############################
cd $BUILD_HOME/installer-build/zm-build

./build.pl --nointeractive