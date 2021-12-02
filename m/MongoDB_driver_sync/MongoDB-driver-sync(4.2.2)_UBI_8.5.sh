# -----------------------------------------------------------------------------
#
# Package	: mongodb/mongo-java-driver
# Version	: 4.1.2
# Source repo	: https://github.com/mongodb/mongo-java-driver
# Tested on	: UBI 8.5
# Script License: Apache License, Version 2 or later
# Maintainer	: Saurabh Gore <Saurabh.Gore@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# Instruction to test script
# run mongodb - 4.0.24+ container to run test cases
# this script tested with mongodb image  quay.io/opencloudio/ibm-mongodb@sha256:563f4b3e582c52b9ae47fac5783fcb8e92ed4285d17893e79a37a5fa2f84c58e

# docker pull registry.access.redhat.com/ubi8
# docker pull quay.io/opencloudio/ibm-mongodb@sha256:563f4b3e582c52b9ae47fac5783fcb8e92ed4285d17893e79a37a5fa2f84c58e
# docker run -d -p 27017:27017  quay.io/opencloudio/ibm-mongodb@sha256:563f4b3e582c52b9ae47fac5783fcb8e92ed4285d17893e79a37a5fa2f84c58e --dbpath=/tmp  --setParameter enableTestCommands=1  --nojournal
# docker run --network host -v /var/run/docker.sock:/var/run/docker.sock -it registry.access.redhat.com/ubi8
# run following script in it in this ubi container. 


WORK_DIR=`pwd`
PACKAGE_NAME=mongo-java-driver
PACKAGE_VERSION="${1:-r4.2.2}"
PACKAGE_URL=https://github.com/mongodb/mongo-java-driver.git

yum -y update 

dnf install git wget unzip  java-11-openjdk-devel  python3 python3-devel -y

export HOME=$WORK_DIR
export WORK_DIR=`pwd`


wget https://services.gradle.org/distributions/gradle-6.0.1-all.zip -P /tmp && unzip -d $WORK_DIR/gradle /tmp/gradle-6.0.1-all.zip
export GRADLE_HOME=$WORK_DIR/gradle/gradle-6.0.1/
export PATH=${GRADLE_HOME}/bin:${PATH}


mkdir -p output
ln -s /usr/bin/python3 /bin/python

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > $WORK_DIR/output/clone_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > $WORK_DIR/output/version_tracker
	exit 0
fi

export HOME_DIR=$WORK_DIR/$PACKAGE_NAME
cd $HOME_DIR
git checkout $PACKAGE_VERSION

cd $WORK_DIR/$PACKAGE_NAME/driver-sync
function try_gradle_with_jdk(){
	echo "Building package with jdk "
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
    export PATH="/usr/lib/jvm/java-11-openjdk":$PATH
	if ! gradle build; then
        exit 0
	fi
	cd $WORK_DIR/$PACKAGE_NAME/driver-sync

	if ! gradle test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > $WORK_DIR/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > $WORK_DIR/output/version_tracker
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > $WORK_DIR/output/test_success
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > $WORK_DIR/output/version_tracker
		exit 0
	fi
}

try_gradle_with_jdk


