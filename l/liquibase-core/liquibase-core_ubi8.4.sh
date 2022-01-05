# -----------------------------------------------------------------------------
#
# Package		: liquibase-core
# Version		: v3.10.3, liquibase-parent-3.5.5
# Source repo	: https://github.com/liquibase/liquibase.git
# Tested on	: ubi 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>
# Language 		: Java
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
# Below script is for two versions
# 1. V3.10.3
# 2. liquibase-parent-3.5.5
# If the script is run without any parameter it builds and validate v3.10.3
# Can provide the version explicitly as well i.e., ./liquibase-core_ubi8.4.sh liquibase-parent-3.5.5
#-----------------------------------------------------------------------------

HOME_DIR=`pwd`
PACKAGE_NAME=liquibase-core
PACKAGE_VERSION=${1:-v3.10.3}
PACKAGE_URL=https://github.com/liquibase/liquibase.git

mkdir -p output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

yum install git maven -y

#clone the repository
git clone $PACKAGE_URL

export WORK_DIR=$HOME_DIR/liquibase/$PACKAGE_NAME
cd $WORK_DIR
git checkout $PACKAGE_VERSION

if ! mvn clean install -Denforcer.skip=true -DskipTests; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi
	
if ! mvn test -Denforcer.skip=true; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_NAME | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	find -name *.jar >> $HOME_DIR/output/post_build_jars.txt
	echo "PATH of .JAR created for $WORK_DIR can be checked in text file:$HOME_DIR/output/post_build_jars.txt"
	exit 0
fi

