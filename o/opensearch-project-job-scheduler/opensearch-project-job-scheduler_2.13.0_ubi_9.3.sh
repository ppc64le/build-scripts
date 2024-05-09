#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : job-scheduler
# Version          : 2.13.0.0
# Source repo      : https://github.com/opensearch-project/job-scheduler
# Tested on        : UBI 9.3
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

sudo yum install -y git gcc make openssl-devel bzip2-devel libffi-devel zlib-devel sqlite-devel java-17-openjdk-devel python3 python3-devel python3-pip

PACKAGE_NAME=job-scheduler
PACKAGE_URL=https://github.com/opensearch-project/job-scheduler
PACKAGE_VERSION=${1:-2.13.0.0}
TARBALL_VERSION=${2:-2.13.0}

git clone ${PACKAGE_URL}
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

CURRENT_DIR=`pwd`

git clone https://github.com/opensearch-project/opensearch-build
cd opensearch-build

curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
export PYENV_ROOT="$HOME/.pyenv"

sudo pip install  pipenv
sudo python3 -m pipenv --python /usr/bin/python3.9

./build.sh manifests/$TARBALL_VERSION/opensearch-$TARBALL_VERSION.yml -s -c OpenSearch

cd ..
./gradlew :spotlessApply

if ! ./gradlew build -x test -x integTest; then
        echo "---------------$PACKAGE_NAME:Build_fails------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
elif ! ./gradlew test integTest -PcustomDistributionUrl=/$CURRENT_DIR/opensearch-build/tar/builds/opensearch/dist/opensearch-min-$TARBALL_VERSION-SNAPSHOT-linux-ppc64le.tar.gz; then
        echo "------------------$PACKAGE_NAME:Test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Test_Fails"
        exit 2
else
        echo "Build and Test Success"
        exit 0
fi
