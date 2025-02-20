#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : reporting
# Version          : 2.10.0.0
# Source repo      : https://github.com/opensearch-project/reporting
# Tested on        : UBI 8.7
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sunidhi Gaonkar<Sunidhi.Gaonkar@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

sudo yum install -y  git gcc patch make java-11-openjdk-devel python39 python39-devel bzip2-devel zlib-devel openssl-devel

export PACKAGE_NAME=reporting
export PACKAGE_URL=https://github.com/opensearch-project/reporting
export PACKAGE_VERSION=${1:-2.10.0.0}

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$PATH:$JAVA_HOME/bin

if ! ./gradlew build; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "Build and Test Success"
        exit 0
fi
