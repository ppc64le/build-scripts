#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : jpype
# Version        : v1.7.1
# Source repo    : https://github.com/jpype-project/jpype.git
# Tested on      : UBI:10.2
# Language       : Python
# Ci-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : tejasBadjateIBM <Tejas.Badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=jpype
PACKAGE_VERSION=${1:-v1.7.1}
PACKAGE_DIR=jpype
PACKAGE_URL=https://github.com/jpype-project/jpype.git
CURRENT_DIR="${PWD}"

# Install necessary system packages
yum install -y git python3.14 python3.14-pip python3.14-devel java-21-openjdk java-21-openjdk-devel gzip tar make wget xz cmake yum-utils openssl-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel

yum install gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ -y

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"
export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
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
python3.14 -m pip install -U pip setuptools wheel
python3.14 -m pip install pytest pytest-cov numpy==2.5.0

# ------------------------------------------------------------------------------------------
if [[ "$(printf '%s\n' "1.7.0" "${PACKAGE_VERSION#v}" | sort -V | head -n1)" == "1.7.0" ]]; then
    echo "Version >= 1.7.0"

    # installing from source as ant rpm is failing to install from CI
    ANT_VERSION=1.10.15
    cd $CURRENT_DIR

    wget -q "https://archive.apache.org/dist/ant/source/apache-ant-${ANT_VERSION}-src.tar.gz"
    tar -xf "apache-ant-${ANT_VERSION}-src.tar.gz"
    cd "apache-ant-${ANT_VERSION}"
    ./build.sh

    mkdir -p "/opt/ant-${ANT_VERSION}"
    cp -a dist/bin dist/lib "/opt/ant-${ANT_VERSION}/"

    ln -sfn "/opt/ant-${ANT_VERSION}" /opt/ant

    export ANT_HOME=/opt/ant
    export PATH="$ANT_HOME/bin:$PATH"

    echo "Ant installation:"
    ant -version
    
    python3.14 -m pip install scikit-build-core
fi

cd $CURRENT_DIR
cd $PACKAGE_DIR

# Install the package 
if ! python3.14 -m pip install --no-build-isolation .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3.14 -c "import jpype; import _jpype; print('JPype native module loaded OK')"

# Install test requirements
python3.14 -m pip install jedi typing_extensions

if [[ "$PACKAGE_VERSION" == "v1.5.0" ]]; then
    python3.14 -m pip install "numpy<2"
fi

python3.14 -c "import jpype"
python3.14 -m pip install -r test-requirements.txt

# Compile JPype Java fixtures
mkdir -p test/classes
find test -name "*.java" | xargs javac -source 8 -target 8 -d test/classes

# Add fixtures + JDBC jars to classpath
export CLASSPATH="$(pwd)/test/classes:$(pwd)/h2.jar:$(pwd)/hsqldb.jar:$(pwd)/sqlite-jdbc.jar:$CLASSPATH"

# Force JVM to use it
export JPYPE_JVM_ARGS="-Djava.class.path=$CLASSPATH"

# Locate JPype support JAR
JPYPE_JAR=$(find /usr/local /usr/lib /opt -name org.jpype.jar -type f 2>/dev/null | head -1)

if [ -n "$JPYPE_JAR" ]; then
    echo "Found JPype support library: $JPYPE_JAR"
    cp "$JPYPE_JAR" "$(pwd)/org.jpype.jar"
    echo "JPype support library copied to:"
    ls -lh "$(pwd)/org.jpype.jar"
else
    echo "ERROR: org.jpype.jar was not found after installation"
    exit 1
fi

# Run tests
if ! python3.14 -m pytest -v --junit-xml=build/test/test.xml test/jpypetest --checkjni --fast; then
    echo "------------------$PACKAGE_NAME: Tests failed ------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Failure"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install & test both successful ---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi