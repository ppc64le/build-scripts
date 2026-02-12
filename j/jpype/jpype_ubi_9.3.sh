#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : jpype
# Version        : v1.5.0
# Source repo    : https://github.com/jpype-project/jpype.git
# Tested on      : UBI 9.3
# Language       : Python
# Ci-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=jpype
PACKAGE_VERSION=${1:-v1.5.0}
PACKAGE_DIR=jpype
PACKAGE_URL=https://github.com/jpype-project/jpype.git

# Install necessary system packages
yum install -y git python3 python3-pip python3-devel java-11-openjdk java-11-openjdk-devel gcc gcc-c++ gzip tar make wget xz cmake yum-utils openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Download JDBC Drivers
wget https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.42.0.0/sqlite-jdbc-3.42.0.0.jar -O sqlite-jdbc.jar
wget https://repo1.maven.org/maven2/org/hsqldb/hsqldb/2.7.2/hsqldb-2.7.2.jar -O hsqldb.jar
wget https://repo1.maven.org/maven2/com/h2database/h2/1.4.200/h2-1.4.200.jar -O h2.jar

# Add drivers to CLASSPATH
export CLASSPATH=$CLASSPATH:$(pwd)/sqlite-jdbc.jar:$(pwd)/hsqldb.jar:$(pwd)/h2.jar

# Install test dependencies
python3 -m pip install -U pip setuptools wheel
python3 -m pip install pytest pytest-cov numpy

# Install the package
if python3 -m pip install --no-build-isolation -e .; then
    echo "------------------$PACKAGE_NAME: Installation successful ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Installation_Success"
    exit 0
fi

python3 -c "import jpype; import _jpype; print('JPype native module loaded OK')"

# Install test requirements
python3 -m pip install jedi typing_extensions

if [[ "$PACKAGE_VERSION" == "v1.5.0" ]]; then
    python3 -m pip install "numpy<2"
else
    python3 -m pip install numpy
fi

python3 -c "import jpype"
python3 -m pip install -r test-requirements.txt

# Compile JPype Java fixtures
mkdir -p test/classes
find test -name "*.java" | xargs javac -source 8 -target 8 -d test/classes

# Add fixtures + JDBC jars to classpath
export CLASSPATH="$(pwd)/test/classes:$(pwd)/h2.jar:$(pwd)/hsqldb.jar:$(pwd)/sqlite-jdbc.jar:$CLASSPATH"

# Force JVM to use it
export JPYPE_JVM_ARGS="-Djava.class.path=$CLASSPATH"

# Run tests
if ! python3 -m pytest -v --junit-xml=build/test/test.xml test/jpypetest --checkjni --fast; then
    echo "------------------$PACKAGE_NAME: Tests failed ------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Failure"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install & test both successful ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi
