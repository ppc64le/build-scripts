# -----------------------------------------------------------------------------
#
# Package	: xmlenc
# Version	: 0.52
# Source repo	: https://github.com/znerd/xmlenc/
# Tested on	: RHEL 8.3
# Script License: Apache License, Version 2 or later
# Maintainer	: BulkPackageSearch Automation <sethp@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=xmlenc
PACKAGE_VERSION=0.52
PACKAGE_URL=https://github.com/znerd/xmlenc/

yum -y update && yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm  && yum install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-2.el8.noarch.rpm http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm && yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless gcc-c++ jq cmake maven ncurses unzip curl git make  gcc-gfortran libX11-devel bzip2-devel xz-devel pcre-devel libcurl-devel openssl-devel openssl sqlite-devel bzip2 libxml2-devel unzip sudo hostname python3 python3-devel java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless wget libXt-devel cairo-devel texlive-latex readline-devel autoconf automake libtool apr-devel apr-util-devel golang ant

OS_NAME=`python3 -c "os_file_data=open('/etc/os-release').readlines();os_info = [i.replace('PRETTY_NAME=','').strip() for i in os_file_data if i.startswith('PRETTY_NAME')];print(os_info[0])"`

function get_checkout_url(){
        url=$1
        CHECKOUT_URL=`python3 -c "url='$url';github_url=url.split('tree')[0];print(github_url);"`
        echo $CHECKOUT_URL
}

function get_working_path(){
        url=$1
        CHECKOUT_URL=`python3 -c "url='$url';github_url,uri=url.split('tree');uris=uri.split('/');print('/'.join(uris[2:]));"`
        echo $CHECKOUT_URL
}

function get_list_of_jars_generated(){
	VALIDATE_DIR=$1
	if test -d "$VALIDATE_DIR/target"; then
		cd "$VALIDATE_DIR/target"
		find -name *.jar >> /home/tester/output/all_jars.txt
	fi
}

CLONE_URL=$(get_checkout_url $PACKAGE_URL)

if [ "$PACKAGE_URL" = "$CLONE_URL" ]; then
        WORKING_PATH="./"
else
        WORKING_PATH=$(get_working_path $PACKAGE_URL)
fi

if ! git clone $CLONE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
	exit 0
fi

HOME_DIR=/home/tester/$PACKAGE_NAME
cd $HOME_DIR
git checkout $PACKAGE_VERSION
cd $WORKING_PATH

# run the test command from test.sh

# Check the type of Java build tool, 
# ant = build.xml file exists
# maven = pom.xml file exists
# gradle = gradle.properties file exists
export GRADLE_HOME=/home/tester/gradle/gradle-7.2-rc-1/
export PATH=${GRADLE_HOME}/bin:${PATH}

function try_mvn_with_jdk11(){
	echo "Building package with jdk 11"
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le/"
	export PATH="/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le/bin/":$PATH
	if ! mvn -T 4 clean install; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
		exit 0
	fi
	cd /home/tester/$PACKAGE_NAME
	if ! mvn test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		get_list_of_jars_generated $HOME_DIR
		exit 0
	fi
}
function try_ant_with_jdk11(){
	echo "Building package with jdk 11"
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le/"
	export PATH="/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le/bin/":$PATH
	if ! ant build; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
		exit 0
	fi
	cd /home/tester/$PACKAGE_NAME
	if ! ant test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		get_list_of_jars_generated $HOME_DIR
		exit 0
	fi
}
function try_gradle_with_jdk11(){
	echo "Building package with jdk 11"
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le/"
	export PATH="/usr/lib/jvm/java-11-openjdk-11.0.12.0.7-0.el8_4.ppc64le/bin/":$PATH
	if ! ./gradlew; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/install_fails
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails" > /home/tester/output/version_tracker
		exit 0
	fi
	cd /home/tester/$PACKAGE_NAME
	if ! gradle test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		get_list_of_jars_generated $HOME_DIR
		exit 0
	fi
}

function try_mvn_with_jdk8(){
	echo "Building package with jdk 1.8"
    export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el8_4.ppc64le/jre/"
	export PATH="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el8_4.ppc64le/jre/bin/":$PATH
	if ! mvn -T 4 clean install; then
        try_mvn_with_jdk11
	fi
	cd /home/tester/$PACKAGE_NAME
	if ! mvn test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		get_list_of_jars_generated $HOME_DIR
		exit 0
	fi
}
function try_ant_with_jdk8(){
	echo "Building package with jdk 1.8"
    export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el8_4.ppc64le/jre/"
	export PATH="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el8_4.ppc64le/jre/bin/":$PATH
	if ! ant build; then
        try_ant_with_jdk11
	fi
	cd /home/tester/$PACKAGE_NAME
	if ! ant test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		get_list_of_jars_generated $HOME_DIR
		exit 0
	fi
}
function try_gradle_with_jdk8(){
	echo "Building package with jdk 1.8"
    export JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el8_4.ppc64le/jre/"
	export PATH="/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.302.b08-0.el8_4.ppc64le/jre/bin/":$PATH
	if ! ./gradlew; then
        try_gradle_with_jdk11
	fi
	cd /home/tester/$PACKAGE_NAME
	if ! gradle test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
		exit 0
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_success
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
		get_list_of_jars_generated $HOME_DIR
		exit 0
	fi
}

if test -f "pom.xml"; then
	try_mvn_with_jdk8
elif test -f "build.xml"; then
	try_ant_with_jdk8
elif test -f "gradlew"; then
	try_gradle_with_jdk8
fi
