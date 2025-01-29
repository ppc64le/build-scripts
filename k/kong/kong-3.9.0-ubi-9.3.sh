#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package           : kong
# Version           : 3.90
# Source repo   : https://github.com/kong/kong
# Tested on         : UBI 9.3
# Language      : Rust
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Kavia Rane <Kavita.Rane2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# --------------------------------------------------------------------------------

if [ -z "${GITHUB_TOKEN}" ]; then
  echo "Environment variable GITHUB_TOKEN not set. Please enter GITHUB_TOKEN"
  echo -n Enter GIHUB_TOKEN :
  read -s githubtoken
  echo
fi
export GITHUB_TOKEN=$githubtoken

if [ -z "${GITHUB_TOKEN}" ]; then
   exit 1
fi
echo " Environmae variable GITHUB_TOKEN set"
  
PACKAGE_NAME=kong
PACKAGE_VERSION=${1:-3.9.0}
PACKAGE_URL=https://github.com/kong/kong/
PYTHON_VERSION=3.11.0
GO_VERSION=1.23.0

dnf update -y
dnf install -y --allowerasing \
    automake \
    gcc \
    gcc-c++ \
    git \
    libyaml-devel \
    make \
    patch \
    perl \
    perl-IPC-Cmd \
    zip unzip \
    valgrind \
    valgrind-devel \
    zlib-devel \
    wget \
    cmake \
    java-21-openjdk-devel \
    tzdata-java \
    curl \
    file \
    openssl-devel

wdir=`pwd`
#Set environment variables
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-21-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

#Install Python from source
if [ -z "$(ls -A $wdir/Python-${PYTHON_VERSION})" ]; then
       wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
       tar xzf Python-${PYTHON_VERSION}.tgz
       rm -rf Python-${PYTHON_VERSION}.tgz
       cd Python-${PYTHON_VERSION}
       ./configure --enable-shared --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions
       make -j ${nproc}
else
       cd Python-${PYTHON_VERSION}
fi

make altinstall
ln -sf $(which python3.11) /usr/bin/python3
ln -sf $(which pip3.11) /usr/bin/pip3
ln -sf /usr/share/pyshared/lsb_release.py /usr/local/lib/python3.11/site-packages/lsb_release.py
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$wdir/Python-3.11.0/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
python3 -V && pip3 -V

#Download source code
cd $wdir
rm -rf $wdir/${PACKAGE_NAME}
if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
  echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
        exit 1
fi
#git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}
BAZEL_VERSION=$(cat .bazelversion)

# Build and setup bazel
cd $wdir
if [ -z "$(ls -A $wdir/bazel)" ]; then
        mkdir bazel
        cd bazel
        wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
        unzip bazel-${BAZEL_VERSION}-dist.zip
        rm -rf bazel-${BAZEL_VERSION}-dist.zip
        #./compile.sh
		
		export BAZEL_JAVAC_OPTS="-J-Xmx20g"
        env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh -j32

fi
export PATH=$PATH:$wdir/bazel/output

#Install rust and cross
curl https://sh.rustup.rs -sSf | sh -s -- -y && source ~/.cargo/env
cargo install cross --version 0.2.1

#Install Golang
cd $wdir
wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xvzf go${GO_VERSION}.linux-ppc64le.tar.gz
rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz

export PATH=$PATH:/usr/local/go/bin
go version
GOBIN=/usr/local/go/bin go install github.com/cli/cli/v2/cmd/gh@v2.50.0	
GHCLI_BIN=/usr/local/go/bin/gh

#Patch and build  Kong
cd $wdir/${PACKAGE_NAME}
git apply --ignore-space-change --ignore-whitespace $wdir/kong-${PACKAGE_VERSION}.patch
make build-release > /dev/null 2>&1 || true

#Patch rules_rust
pushd $(find $HOME/.cache/bazel -name rules_rust) 
git apply --ignore-space-change --ignore-whitespace  $wdir/kong-${PACKAGE_VERSION}-rules_rust-0.42.1.patch


#Build cargo-bazel native binary
cd crate_universe
cargo update -p time
cross build --release --locked --bin cargo-bazel --target=powerpc64le-unknown-linux-gnu 
export CARGO_BAZEL_GENERATOR_URL=file://$(pwd)/target/powerpc64le-unknown-linux-gnu/release/cargo-bazel
export CARGO_BAZEL_REPIN=true
echo "cargo-bazel build successful!"
popd



#Build kong .deb package
echo "Building Kong debian package..."
cd $wdir/${PACKAGE_NAME}
make package/deb  > /dev/null 2>&1 || true

cp -f $GHCLI_BIN $(find $HOME/.cache/bazel -type d -name gh_linux_ppc64le)/bin

if ! make package/deb ; then
   echo "------------------$PACKAGE_NAME: package/deb build_fails-------------------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
   exit 1
fi


if ! make package/rpm ; then
   echo "------------------$PACKAGE_NAME: package/rpm build_fails-------------------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
   exit 1
fi

cp $(find / -name kong.el8.ppc64le.rpm) $wdir
export KONG_RPM=$wdir/kong.el8.ppc64le.rpm


#Install and configure postgreSQL server
cd $wdir/
wget https://ftp.postgresql.org/pub/source/v13.0/postgresql-13.0.tar.gz
tar -zxvf postgresql-13.0.tar.gz
cd postgresql-13.0
./configure --without-readline
make
make install

/usr/sbin/useradd postgresql
mkdir /dbdirectory/
/usr/sbin/usermod -d /dbdirectory/ postgresql
chown postgresql:postgresql /dbdirectory/
chmod -R 755  /dbdirectory/

su postgresql -c '/usr/local/pgsql/bin/initdb -D /dbdirectory/data/'
su postgresql -c '/usr/local/pgsql/bin/pg_ctl -D /dbdirectory/data/ start'
su postgresql -c '/usr/local/pgsql/bin/psql -d template1 -c "CREATE USER kong;"'
su postgresql -c '/usr/local/pgsql/bin/psql -d template1 -c "CREATE DATABASE kong OWNER kong;"'
su postgresql -c "/usr/local/pgsql/bin/psql -d template1 -c \"ALTER USER kong WITH PASSWORD 'password';\""
su postgresql -c '/usr/local/pgsql/bin/psql -d template1 -c "CREATE USER kong_tests;"'
su postgresql -c '/usr/local/pgsql/bin/psql -d template1 -c "CREATE DATABASE kong_tests OWNER kong_tests;"'
su postgresql -c "/usr/local/pgsql/bin/psql -d template1 -c \"ALTER USER kong_tests WITH PASSWORD 'password';\""


#Build unit test dependencies
bazel_out=$(find $HOME/.cache/bazel -name bazel-out)
export PATH=$PATH:$bazel_out/ppc-opt/bin/external/openresty/luajit/bin

git clone https://github.com/luarocks/luarocks.git
cd luarocks
git checkout v3.11.1
./configure
make install

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$bazel_out/ppc-opt/bin/external/openresty/luajit/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$bazel_out/ppc-opt/bin/build/kong-dev/kong/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:kong/kong

cp -r $wdir/kong/bazel-bin/build/kong-dev/openresty/ /usr/local/
luarocks install --force luaexpat EXPAT_DIR=$bazel_out/ppc-opt/bin/external/libexpat/libexpat
luarocks install --force lua-resty-aws

cd $wdir/${PACKAGE_NAME}
make install  > /dev/null 2>&1 || true
make install

cp -r $bazel_out/ppc-opt/bin/external/openresty/openresty /kong/bazel-bin/build/kong-dev/

# Run unit test
if ! ( make test-custom test_spec=spec/01-unit/29-lua_cjson_large_str_spec.lua && make test) ; then
   echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  build_success_but_test_fails"
   exit 2
else
   echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
fi

#Conclude
set +ex
echo "Build successful!"
echo "Kong RPM package available at [$KONG_RPM]"
