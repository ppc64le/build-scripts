#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package       : 3scale/APIcast
# Version       : v3.15.0
# Source repo   : https://github.com/3scale/APIcast.git
# Tested on     : UBI 9.3
# Language      : Lua,Perl
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Gupta <Shubham.Gupta43@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


# Variables
set -e
set -x
ARCH=$(uname -m)

PACKAGE_VERSION=${1:-v3.15.0}
PACKAGE="APIcast"
REPO_URL="https://github.com/3scale/APIcast.git"
CLONE_DIR="cloned_repo"
DOCKER_IMAGE_NAME="apicastimg"


# Clone the Git repository
git clone $REPO_URL $CLONE_DIR

# Check if the clone was successful
if [ $? -ne 0 ]; then
  echo "Error cloning the repository."
  exit 1
fi

# Change to the cloned directory
cd $CLONE_DIR || { echo "Failed to change directory to $CLONE_DIR"; exit 1; }

# Get the absolute path of the cloned directory
CLONE_DIR_PATH=$(pwd)

# Check if the Makefile exists
if [ ! -f Makefile ]; then
  echo "Makefile not found."
  exit 1
fi

# Use sed to find and replace the platform in the Makefile
sed -i '/^dev-build:/,/^$/s|build --platform linux/amd64 -t $(IMAGE_NAME) \\|build --platform linux/ppc64le -t $(IMAGE_NAME) \\|' Makefile

# Check if the sed command was successful
if [ $? -ne 0 ]; then
  echo "Error updating the Makefile."
  exit 1
fi

echo "Makefile updated successfully."

# Check if Dockerfile.devel exists
if [ ! -f Dockerfile.devel ]; then
  echo "Dockerfile.devel not found."
  exit 1
fi

# Use sed to find and add --skip-broken after jaegertracing-cpp-client-${JAEGERTRACING_CPP_CLIENT_RPM_VERSION}
sed -i 's|jaegertracing-cpp-client-${JAEGERTRACING_CPP_CLIENT_RPM_VERSION}|jaegertracing-cpp-client-${JAEGERTRACING_CPP_CLIENT_RPM_VERSION} --skip-broken|' Dockerfile.devel

# Check if the sed command was successful
if [ $? -ne 0 ]; then
  echo "Error updating Dockerfile.devel."
  exit 1
fi

echo "Dockerfile.devel updated successfully."

# Run make dev-build with the specified IMAGE_NAME
make dev-build IMAGE_NAME=${DOCKER_IMAGE_NAME}

# Check if the make command was successful
if [ $? -ne 0 ]; then
  echo "Error running make dev-build."
  exit 1
fi

echo "dev-build completed successfully."

# Check if docker-compose-devel.yml exists
if [ ! -f docker-compose-devel.yml ]; then
  echo "docker-compose-devel.yml not found."
  exit 1
fi

# Use sed to find and replace the image name under the development section in docker-compose-devel.yml
sed -i '/development:/,/^$/s|\${IMAGE:-quay.io/3scale/apicast-ci:openresty-1.21.4-1}|\${IMAGE:-'${DOCKER_IMAGE_NAME}'}|' docker-compose-devel.yml

# Use sed to find and replace the platfrom from Linux/amd64 to ppc64le under the development section in docker-compose-devel.yml
sed -i '/development:/,/^$/s|platform: "linux/amd64"|platform: "linux/ppc64le"|' docker-compose-devel.yml


# Check if the sed command was successful
if [ $? -ne 0 ]; then
  echo "Error updating docker-compose-devel.yml."
  exit 1
fi

echo "docker-compose-devel.yml updated successfully."

#download required packages
yum install -y \
        cpan \
        curl \
        dos2unix \
        findutils \
        gcc-c++ \
        make \
        ncurses-devel \
        patch \
        pcre-devel \
        perl \
        postgresql-devel \
        readline \
        sudo \
        tar \
        tar \
        unzip \
        wget \
        yum


# installing openresty
PACKAGE_NAME="openresty"
PACKAGE_VERSION="1.21.4.3"
SOURCE_ROOT="$(pwd)"

cd $SOURCE_ROOT
wget https://openresty.org/download/openresty-${PACKAGE_VERSION}.tar.gz
tar -xvf openresty-${PACKAGE_VERSION}.tar.gz
# add redis2-nginx-module-0.15 module
wget https://github.com/openresty/redis2-nginx-module/archive/refs/tags/v0.15.tar.gz
tar -xvf v0.15.tar.gz


cd $SOURCE_ROOT/openresty-${PACKAGE_VERSION}
./configure --with-pcre-jit \
        --with-ipv6 \
        --without-http_redis2_module \
        --with-http_iconv_module \
        --with-http_postgres_module \
        --with-http_realip_module \
        --with-http_v2_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-mail_smtp_module \
        --with-http_stub_status_module \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_secure_link_module \
        --with-http_random_index_module \
        --with-http_gzip_static_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-threads \
        --with-compat \
        --add-module=../redis2-nginx-module-0.15
make -j2
sudo make install
#Set Environment Variable
export PATH=/usr/local/openresty/bin:$PATH
sudo cp -r /usr/local/openresty/ /usr/local/bin
# openresty installation finished

# luajit2 installation begins --------------------------------------------------------------
# Variables
LUAJIT_REPO="https://github.com/openresty/luajit2.git"
INSTALL_DIR="/usr/local"

# Clone the LuaJIT repository
echo "Cloning the LuaJIT repository..."
git clone "${LUAJIT_REPO}"

# Navigate to the repository directory
cd luajit2

# Build LuaJIT
echo "Building LuaJIT..."
make

# Install LuaJIT
echo "Installing LuaJIT..."
sudo make install PREFIX="${INSTALL_DIR}"

# Set up LuaJIT environment variables
echo "Setting up environment variables..."
echo "export PATH=\$PATH:${INSTALL_DIR}/bin" >> ~/.profile
echo "export LUAJIT_LIB=${INSTALL_DIR}/lib" >> ~/.profile
echo "export LUAJIT_INC=${INSTALL_DIR}/include/luajit-2.1" >> ~/.profile

# Apply the changes to the current shell session
source ~/.profile

# Verify the installation
echo "Verifying LuaJIT installation..."
luajit -v

# Clean up
cd ..
rm -rf luajit2

echo "LuaJIT installation completed."
echo "luajit2 installation-------------------------Finished-----------------------------------"


# Note - luarocks installation is removed becuase it was giving issue with openresty

# installing openssl package (optional)
yum install openssl openssl-devel
wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz
tar -zxvf openssl-1.1.1w.tar.gz
./configure --with-openssl=./openssl-1.1.1w

# install required packages
yum install zlib zlib-devel
./configure

yum install lua lua-devel

if [ $? -ne 0 ]; then
    echo "------------------$PACKAGE:build_fails---------------------------------------"
    echo "$REPO_URL $PACKAGE"
    exit 1
fi

# change dirct to the cloned repo
cd ..

# to make development container
make development &

# Wait for the container to start up
# Adjust this if needed for your container to fully initialize
sleep 5  


# Note - This script validates till unit test, integration tests are not working properly due to some dependencies
# that are not supported on power.

# Execute commands inside the running container
if docker exec -it --user root apicast_build_0-development-1 bash -c "make dependencies && make busted"; then
    echo "------------------$PACKAGE:Both_build_and_test_passed---------------------------------------"
    echo "$REPO_URL $PACKAGE"
    exit 0

else
    echo "------------------$PACKAGE:test_fails---------------------------------------"
    echo "$REPO_URL $PACKAGE"
    exit 2

fi


