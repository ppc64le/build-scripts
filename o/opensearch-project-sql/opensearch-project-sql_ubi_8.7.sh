#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : sql
# Version          : 2.11.0.0
# Source repo      : https://github.com/opensearch-project/sql
# Tested on        : UBI 8.7
# Language         : Java
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Pratik Tonage<Pratik.Tonage@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

sudo yum install -y git gcc patch make java-11-openjdk-devel python39 python39-devel bzip2-devel zlib-devel openssl-devel

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)

PACKAGE_NAME=sql
PACKAGE_URL=https://github.com/opensearch-project/sql
PACKAGE_VERSION=${1:-2.11.0.0}

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
# update the path env. variable 
export PATH=$PATH:$JAVA_HOME/bin

cd $CURRENT_DIR
git clone https://github.com/opensearch-project/opensearch-build
cd opensearch-build

curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
export PYENV_ROOT="$HOME/.pyenv"

sudo ln -s /usr/bin/pip3 /usr/bin/pip
sudo pip install  pipenv
sudo python3 -m pipenv --python /usr/bin/python3.9

git apply $SCRIPT_DIR/tarball.diff
sudo ./build.sh manifests/2.11.0/opensearch-2.11.0.yml -s -c OpenSearch

cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! ./gradlew build -x test -x :integ-test:integTest -x :doctest:doctest; then
        echo "------------------$PACKAGE_NAME:Build_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
elif ! ./gradlew test -PcustomDistributionUrl=$CURRENT_DIR/opensearch-build/tar/builds/opensearch/dist/opensearch-min-2.11.0-SNAPSHOT-linux-ppc64le.tar.gz -Dtests.heap.size=4096m ; then
        echo "------------------$PACKAGE_NAME:Build_and _test_fails---------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 2
else
        echo "Build and Test Success"
        exit 0
fi

#While testing we have excluded integration test as it requires rhel 9 support.
