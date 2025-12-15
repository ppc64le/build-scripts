# -----------------------------------------------------------------------------
#
# Package	: liquibase-hibernate5
# Version	: 3.10.1
# Source repo	: https://github.com/liquibase/liquibase-hibernate.git
# Tested on	: UBI 8.4
# Language      : Java
# Ci-Check	: True
# Script License: Apache License, Version 2 or later
# Maintainer	: Sapna Shukla <Sapna.Shukla@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
# ----------------------------------------------------------------------------
# The script takes the tag as input, default is 3.10.1
# The tags for this package is in the format liquibase-hibernate5-<tag/version number>
# To run the script for other specific versions provide just the tag/version number i.e, ./liquibase-hibernate5 3.10.2
# ----------------------------------------------------------------------------


HOME_DIR=`pwd`
PACKAGE_NAME=liquibase-hibernate
PACKAGE_VERSION=${1:-3.10.1}
PACKAGE_URL=https://github.com/liquibase/liquibase-hibernate.git

mkdir -p output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

yum install git maven -y

#clone the repository
git clone $PACKAGE_URL

export WORK_DIR=$HOME_DIR/$PACKAGE_NAME
cd $WORK_DIR
CHECKOUT_VAL=liquibase-hibernate5-$PACKAGE_VERSION
git checkout $CHECKOUT_VAL

if ! mvn clean install -DskipTests; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | master | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi
	
if ! mvn test; then
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

