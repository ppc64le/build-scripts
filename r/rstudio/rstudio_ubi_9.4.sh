#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : rstudio
# Version       : main
# Source repo   : https://github.com/rstudio/rstudio
# Tested on     : UBI 9.4
# Language      : Java/C++
# Travis-Check  : False
# Maintainer    : Tejas Badjate <Tejas.Badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -xe

date
echo "Start building RStudio server PPC64LE from source..."

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)
TMPWS_DIR=/tmp
cd ${TMPWS_DIR}

# Set environment configuration
export RSTUDIO_VERSION_MAJOR=2024
export RSTUDIO_VERSION_MINOR=04
export RSTUDIO_VERSION_PATCH=2
export RSTUDIO_VERSION_SUFFIX=-dev+764
export PACKAGE_OS="RHEL 9"
export RSTUDIO_SERVER_VERSION=2024.04.2+764

ARCH=$(uname -m)

export LD_LIBRARY_PATH=/usr/local:/usr/lib64

# installing dependencies
if ! rpm -q openssl-devel &>/dev/null; then
     yum install -y openssl-devel
else
yum install -y sudo wget git yum-utils llvm cmake \
	           libsecret-devel npm nodejs
yum install -y chkconfig 

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm;
sudo dnf install python3 python3-devel -y      
	       
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

# installing R 
dnf install -y R-core R-core-devel libsqlite3x-devel soci-sqlite3

# get source
cd ${TMPWS_DIR}
if [ -d rstudio ] ; then
  rm -rf rstudio
fi

# clone rStudio server repository
echo "clone rStudio server repository"
git clone https://github.com/rstudio/rstudio.git
if [ ! -d ${TMPWS_DIR}/rstudio ]; then
  echo "ERROR: Failed to clone rStudio server repository"
  exit 1
fi

# change directory to rstudio
cd ${TMPWS_DIR}/rstudio
      git checkout tags/v2024.04.2+764

# add patch
git apply $SCRIPT_DIR/rstudio-server.patch
sed -i '62s/%Y-%m-%d/2024-07-05/' CMakeGlobals.txt
sed -i '61s/%Y/2024/' CMakeGlobals.txt

cd ${TMPWS_DIR}/rstudio

# install dependencies
cd ./dependencies/linux
sed -i 's/sudo yum install -y openssl-devel/#sudo yum install -y openssl-devel/' ./install-dependencies-yum
sed -i 's/sudo yum install -y fakeroot/#sudo yum install -y fakeroot/' ./install-dependencies-yum

cd ${TMPWS_DIR}/rstudio

cd dependencies/common
sed -i '45 a "Linux-ppc64le") NODE_FILE="node-v${NODE_VERSION}-linux-ppc64le" ;; ' ./install-node
sed -i '32s/.*/export NODE_BASE_URL=https:\/\/nodejs.org\/dist\/v${NODE_VERSION}\//' ./install-npm-dependencies
sed -i '47 a cp ${NODE_SUBDIR}/bin/node /usr/bin/ ' ./install-npm-dependencies
sed -i 's/\.\/install-sentry-cli/#\.\/install-sentry-cli/' ./install-common

cd ..
cd linux
RSTUDIO_DISABLE_CRASHPAD=1  ./install-dependencies-yum
#unset R_HOME                   # while building with the base image of R
cd ../../
mkdir build && cd build

cd ${TMPWS_DIR}/rstudio/build

cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_INSTALL_PREFIX=/usr/lib/rstudio-server -DCMAKE_BUILD_TYPE=Release -DQUARTO_ENABLED=False || { echo "CMake configuration failed"; exit 1; }
cd ${TMPWS_DIR}/rstudio/src/gwt/lib/quarto
sed -i '23 s/turbo/turbo-linux-ppc64le/' package.json
sed -i '23 s/\^1.8.5/1.4.7/'  package.json
export JAVA_HOME=/etc/alternatives/java_sdk_1.8.0
cd ${TMPWS_DIR}/rstudio/build
PATH=${TMPWS_DIR}/rstudio/dependencies/common/node/18.18.2/bin:$PATH make install || { echo "Build or install failed"; exit 1; }

# package RStudio server
cd ${TMPWS_DIR}
tar czf rstudio_server_${ARCH}_${RSTUDIO_SERVER_VERSION}.tar.gz /usr/lib/rstudio-server

USERNAME=rstudio
USER_UID=1000
USER_GID=$USER_UID

groupadd --gid $USER_GID $USERNAME 
useradd --uid $USER_UID --gid $USER_GID -m $USERNAME 
echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME 
chmod 0775 /etc/sudoers.d/$USERNAME 
echo "$USERNAME:$USERNAME" | sudo chpasswd

cp /usr/lib/rstudio-server/extras/init.d/redhat/rstudio-server /etc/init.d/
/sbin/chkconfig --add rstudio-server
ln -f -s /usr/lib/rstudio-server/extras/init.d/redhat/rstudio-server /usr/sbin/rstudio-server
yum install -y initscripts lsof
mkdir -p /var/run/rstudio-server
mkdir -p /var/log/rstudio-server 
mkdir -p /var/lib/rstudio-server 
mkdir -p /var/lock/subsys/
rstudio-server start

cd /${TMPWS_DIR}/rstudio/src/gwt
sed -i "412i\         \<jvmarg value='"-Xms16m"'/>" build.xml
sed -i "413i\         \<jvmarg value='"-Xmx1536m"'/>" build.xml
cd /${TMPWS_DIR}/rstudio/build/src/gwt &&  ./gwt-unit-tests.sh

TMPWS_DIR=/tmp
cd /${TMPWS_DIR}/rstudio/build/src/
chown rstudio: cpp

cd /${TMPWS_DIR}/rstudio/src/cpp/tests/testthat/
chown rstudio: themes

cd /${TMPWS_DIR}/rstudio/build/src/cpp &&  ./rstudio-tests --scope core

#su rstudio
sudo -E -u rstudio bash -c 'bash << EOF
export TMPWS_DIR=/tmp

cd \${TMPWS_DIR}/rstudio/build/src/cpp &&  ./rstudio-tests --scope r
cd \${TMPWS_DIR}/rstudio/build/src/cpp &&  ./rstudio-tests --scope rsession
# Travis check is set to false as the build exceeded the maximum time limit for jobs.
EOF'

sudo -E -u root bash -c 'bash << EOF
#cleanup
yum remove -y openssl-devel libsqlite3x-devel libsecret-devel
echo "Done building RStudio server"
EOF'
