#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package		:
# Version		:
# Source repo	:
# Tested on	: UBI:9.3
# Language      : Java
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: ICH <ich@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=
PACKAGE_VERSION=
PACKAGE_URL=

export HOME=/

yum install -y gcc gcc-c++ gcc-gfortran git xz cmake make yum-utils wget sudo llvm
yum install libcurl-devel openssl openssl-devel -y

yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
yum install -y --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

yum install -y libxml2-devel bzip2-devel gcc-c++ libffi libffi-devel sqlite-devel 
yum install -y libpng-devel sqlite-libs libjpeg-devel libicu-devel oniguruma-devel readline-devel 
yum install -y libtidy-devel libxslt-devel libzip-devel diffutils autoconf bison-devel git bzip2 file cargo
yum install -y --skip-broken nodejs nodejs-devel nodejs-packaging npm ncurses

yum install -y java-21-openjdk.ppc64le java-21-openjdk-devel java-21-openjdk-headless java-17-openjdk maven java-17-openjdk-devel java-17-openjdk-headless java-11-openjdk java-11-openjdk-devel java-11-openjdk-headless java-1.8.0-openjdk.ppc64le java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless
yum install -y hostname python3 python3-devel cairo-devel texlive-latex readline-devel apr-devel apr-util-devel golang ant tar libevent-devel java-latest-openjdk sudo
# install gradle
wget https://services.gradle.org/distributions/gradle-8.2-bin.zip -P /tmp && unzip -o -d /gradle /tmp/gradle-8.2-bin.zip
export GRADLE_HOME=/gradle/gradle-8.2/
export PATH=${GRADLE_HOME}/bin:${PATH}

# install maven
wget https://downloads.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz && tar -xzf apache-maven-3.9.9-bin.tar.gz -C /usr/lib/
export M2_HOME=/usr/lib/apache-maven-3.9.9
export M2=/usr/lib/apache-maven-3.9.9/bin/
export MAVEN_OPTS="-Xms2G -Xmx4G"

export PATH=/usr/lib/apache-maven-3.9.9/bin/:$PATH

# install scala
rm -f /etc/yum.repos.d/bintray-rpm.repo && curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo && mv sbt-rpm.repo /etc/yum.repos.d/ && yum install -y sbt

ln -s /usr/bin/python3 /bin/python

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

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
	FILE_NAME=$2
	find -name *.jar >> $FILE_NAME
}

CLONE_URL=$(get_checkout_url $PACKAGE_URL)

if [ "$PACKAGE_URL" = "$CLONE_URL" ]; then
        WORKING_PATH="./"
else
        WORKING_PATH=$(get_working_path $PACKAGE_URL)
fi

if ! git clone $CLONE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

export HOME_DIR=$PACKAGE_NAME
cd $HOME_DIR
git checkout $PACKAGE_VERSION
cd $WORKING_PATH


function try_mvn_with_jdk17_all(){
	pom_present=(`find . -print | grep pom.xml`)
	unset JAVA_HOME
	export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
	export PATH=$JAVA_HOME/bin:$PATH

	for pom_url in "${pom_present[@]}";do
		if ! mvn -f $pom_url -T 4 clean install -DskipTests -Dgpg.skip -Dmaven.javadoc.skip=true; then
			echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
			echo "$PACKAGE_VERSION $PACKAGE_NAME"
			echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails"
			exit 1
		fi
	done

	for pom_url in "${pom_present[@]}";do
        echo $pom_url
        if ! mvn -f $pom_url test;then
			echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME"
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"  
			exit 2
		else
			echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME"
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
			get_list_of_jars_generated $HOME_DIR post_build_jars.txt
			exit 0
		fi
	done

}

function try_mvn_with_jdk11_all(){
	pom_present=(`find . -print | grep pom.xml`)

	unset JAVA_HOME
	export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
	export PATH=$JAVA_HOME/bin:$PATH
	for pom_url in "${pom_present[@]}";do
        if ! mvn -f $pom_url -T 4 clean install -DskipTests -Dgpg.skip -Dmaven.javadoc.skip=true;then
			try_mvn_with_jdk17_all
		fi
	done

	for pom_url in "${pom_present[@]}";do
        echo $pom_url
        if ! mvn -f $pom_url test;then
			echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME" 
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
			exit 2
		else
			echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
			echo "$PACKAGE_URL $PACKAGE_NAME"
			echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
			get_list_of_jars_generated $HOME_DIR post_build_jars.txt
			exit 0
		fi
	done
}



# run the test command from test.sh

# Check the type of Java build tool, 
# ant = build.xml file exists
# maven = pom.xml file exists
# gradle = gradle.properties file exists
export GRADLE_HOME=gradle/gradle-8.2/
export PATH=${GRADLE_HOME}/bin:${PATH}

function set_sbt_opts(){
	if test -f ".sbtopts"; then
		export SBT_OPTS="$(<.sbtopts) "
	else
		export SBT_OPTS="-Xmx4G -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=2G -Xss2M  -Duser.timezone=GMT"
	fi
}

function try_gradle_with_jdk21(){
	echo "Building package with jdk 21"
	unset JAVA_HOME
	export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
    export PATH=$JAVA_HOME/bin:$PATH
	
    java -version
	chmod u+x ./gradlew
	if ! ./gradlew -x test; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails" 
		exit 1
	fi
	cd $PACKAGE_NAME
	if ! ./gradlew test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
		exit 2
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
		get_list_of_jars_generated $HOME_DIR post_build_jars.txt
		exit 0
	fi
}

function try_mvn_with_jdk21(){

	echo "Building package with jdk 21"
	unset JAVA_HOME
	export JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
    export PATH=$JAVA_HOME/bin:$PATH
	java -version

	if ! mvn -T 4 clean install -DskipTests -Dgpg.skip -Dmaven.javadoc.skip=true; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails" 
		exit 1
	fi
	cd $PACKAGE_NAME
	if ! mvn test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
		exit 2
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
		get_list_of_jars_generated $HOME_DIR post_build_jars.txt
		exit 0
	fi
}

function try_mvn_with_jdk17(){
	echo "Building package with jdk 17"
	unset JAVA_HOME
	export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
	export PATH=$JAVA_HOME/bin:$PATH
	if ! mvn -T 4 clean install -DskipTests -Dgpg.skip -Dmaven.javadoc.skip=true; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails" 
		try_mvn_with_jdk21
	fi
	cd $PACKAGE_NAME
	if ! mvn test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
		exit 2
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
		get_list_of_jars_generated $HOME_DIR post_build_jars.txt
		exit 0
	fi
}

function try_ant_with_jdk17(){
	echo "Building package with jdk 17"
	unset JAVA_HOME
    export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
	export PATH=$JAVA_HOME/bin:$PATH
	if ! ant build; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails" 
		exit 1
	fi
	cd $PACKAGE_NAME
	if ! ant test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
		exit 2
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
		get_list_of_jars_generated $HOME_DIR post_build_jars.txt
		exit 0
	fi
}
function try_gradle_with_jdk17(){
	echo "Building package with jdk 17"
	unset JAVA_HOME
        export JAVA_HOME="/usr/lib/jvm/java-17-openjdk"
	export PATH=$JAVA_HOME/bin:$PATH
	chmod u+x ./gradlew
	if ! ./gradlew -x test; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails" 
		try_gradle_with_jdk21
	fi
	cd $PACKAGE_NAME
	if ! ./gradlew test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
		exit 2
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
		get_list_of_jars_generated $HOME_DIR post_build_jars.txt
		exit 0
	fi
}

function try_mvn_with_jdk11(){
	echo "Building package with jdk 11"
	unset JAVA_HOME
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
	export PATH=$JAVA_HOME/bin:$PATH
	if ! mvn -T 4 clean install -DskipTests -Dgpg.skip -Dmaven.javadoc.skip=true; then
        try_mvn_with_jdk17
	fi
	cd $PACKAGE_NAME
	if ! mvn test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
		exit 2
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
		get_list_of_jars_generated $HOME_DIR post_build_jars.txt
		exit 0
	fi
}

function try_ant_with_jdk11(){
	echo "Building package with jdk 11"
	unset JAVA_HOME
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
	export PATH=$JAVA_HOME/bin:$PATH
	if ! ant build; then
        try_ant_with_jdk17
	fi
	cd  $PACKAGE_NAME
	if ! ant test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
		exit 2
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
		get_list_of_jars_generated $HOME_DIR post_build_jars.txt
		exit 0
	fi
}

function try_gradle_with_jdk11(){
	echo "Building package with jdk 11"
	unset JAVA_HOME
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
	export PATH=$JAVA_HOME/bin:$PATH
	chmod u+x ./gradlew
	if ! ./gradlew -x test; then
        try_gradle_with_jdk17
	fi
	cd  $PACKAGE_NAME
	if ! ./gradlew test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
		exit 2
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
		get_list_of_jars_generated $HOME_DIR post_build_jars.txt
		exit 0
	fi
}

function try_sbt_with_jdk11(){
	echo "Building package with jdk 11"
	unset JAVA_HOME
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
	export PATH=$JAVA_HOME/bin:$PATH
	if ! sbt compile; then
		echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
		echo "$PACKAGE_VERSION $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails" 
		exit 1
	fi
	cd  $PACKAGE_NAME
	if ! sbt test; then
		echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" 
		exit 2
	else
		echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
		echo "$PACKAGE_URL $PACKAGE_NAME" 
		echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" 
		get_list_of_jars_generated $HOME_DIR post_build_jars.txt
		exit 0
	fi
}

get_list_of_jars_generated $HOME_DIR pre_build_jars.txt
if test -f "pom.xml"; then
	export MAVEN_OPTS="-Xmx4G"
	try_mvn_with_jdk11
elif test -f "build.xml"; then
	try_ant_with_jdk11
elif test -f "gradlew"; then
	try_gradle_with_jdk11
elif test -f "build.sbt"; then
	set_sbt_opts
	try_sbt_with_jdk11
else
	try_mvn_with_jdk11_all
fi