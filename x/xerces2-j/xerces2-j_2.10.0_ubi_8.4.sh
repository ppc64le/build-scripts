# -----------------------------------------------------------------------------
#
# Package	: xerces2-j
# Version	: Xerces-J_2_10_0
# Source repo	: https://github.com/apache/xerces2-j
# Tested on	: UBI 8.4
# Script License: Apache License, Version 2 or later
# Maintainer	: Atharv Phadnis <Atharv.Phadnis@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=xerces2-j
PACKAGE_VERSION=Xerces-J_2_10_0
PACKAGE_URL=https://github.com/apache/xerces2-j

yum install -y java-1.8.0-openjdk-devel git wget

#Install ANT
wget https://downloads.apache.org/ant/binaries/apache-ant-1.10.12-bin.tar.gz
tar -xf apache-ant-1.10.12-bin.tar.gz
# Set ANT_HOME variable 
export ANT_HOME=${pwd}/apache-ant-1.10.12
# update the path env. variable 
export PATH=${PATH}:${ANT_HOME}/bin

HOME_DIR=`pwd`

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | Fail |  Clone_Fails"
	exit 0
fi

cd $HOME_DIR/$PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Changes to make xerces2-j work with java-11
sed -i '/import org.w3c.dom.Node;/i import org.w3c.dom.Document;' src/org/apache/html/dom/HTMLElementImpl.java
sed -i '/import import org.w3c.dom.html.HTMLIFrameElement;/i import org.w3c.dom.Document;' src/org/apache/html/dom/HTMLIFrameElementImpl.java
sed -i '/import org.w3c.dom.html.HTMLObjectElement;/i import org.w3c.dom.Document;' src/org/apache/html/dom/HTMLObjectElementImpl.java
sed -i '/public String getId() {/i     public Document getContentDocument() {\n        return ownerDocument.getOwnerDocument();\n    }' src/org/apache/html/dom/HTMLElementImpl.java

cd $HOME_DIR/$PACKAGE_NAME
if ! ant jars; then
	echo "------------------$PACKAGE_NAME:build_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Fail |  Build_Fails"
	exit 0
else
	echo "------------------$PACKAGE_NAME:build_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Pass |  Build_Success"
	exit 0
fi


# There were 7 Test failures:
# 1) testSetTrueDocument(schema.config.IgnoreXSIType_C_C_Test)junit.framework.AssertionFailedError: {validity} was <partial> but it should have been <none> expected:<0> but was:<1>
# 2) testSetTrueFragment(schema.config.IgnoreXSIType_C_C_Test)junit.framework.AssertionFailedError: {validity} was <partial> but it should have been <none> expected:<0> but was:<1>
# 3) testSetTrueDocument(schema.config.IgnoreXSIType_C_AC_Test)junit.framework.AssertionFailedError: {validity} was <partial> but it should have been <none> expected:<0> but was:<1>
# 4) testSetTrueFragment(schema.config.IgnoreXSIType_C_AC_Test)junit.framework.AssertionFailedError: {validity} was <partial> but it should have been <none> expected:<0> but was:<1>
# 5) testSetTrueDocument(schema.config.IgnoreXSIType_C_CA_Test)junit.framework.AssertionFailedError: {validity} was <partial> but it should have been <none> expected:<0> but was:<1>
# 6) testSetTrueFragment(schema.config.IgnoreXSIType_C_CA_Test)junit.framework.AssertionFailedError: {validity} was <partial> but it should have been <none> expected:<0> but was:<1>
# 7) testUsingOnlyGrammarPool(schema.config.UseGrammarPoolOnly_True_Test)junit.framework.AssertionFailedError: {validity} was <partial> but it should have been <none> expected:<0> but was:<1>
cd $HOME_DIR/$PACKAGE_NAME
if ! ant test; then
	echo "------------------$PACKAGE_NAME:test_fails---------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Fail |  Test_Fails"
	exit 0
else
	echo "------------------$PACKAGE_NAME:test_success-------------------------"
	echo  "$PACKAGE_URL $PACKAGE_NAME " 
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Pass |  Test_Success"
	exit 0
fi