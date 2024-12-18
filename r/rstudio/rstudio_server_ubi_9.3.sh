#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : rstudio
# Version       : v2024.09.0+375
# Source repo   : https://github.com/rstudio/rstudio
# Tested on     : UBI 9.3
# Language      : Java/C++
# Travis-Check  : True
# Maintainer    : Guarav.Bankar@ibm.com
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_URL=https://github.com/rstudio/rstudio.git
PACKAGE_NAME=rstudio
PACKAGE_VERSION=${1:-v2024.09.0+375}
export ARCH=$(uname -m)

CURRENT_DIR=`pwd`
SCRIPT=$(readlink -f $0)
SCRIPT_DIR=$(dirname $SCRIPT)
TMPWS_DIR=/tmp
cd ${TMPWS_DIR}
export LD_LIBRARY_PATH=/usr/local:/usr/lib64

#installing dependencies
yum install -y sudo wget openssl-devel git yum-utils llvm cmake \
                   libsecret-devel npm nodejs chkconfig

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm;
sudo dnf install python3 python3-devel -y

yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official
mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

#installing R
dnf install -y R-core R-core-devel libsqlite3x-devel soci-sqlite3

git clone ${PACKAGE_URL}
cd ${TMPWS_DIR}/${PACKAGE_NAME}
git checkout tags/${PACKAGE_VERSION}
git apply $SCRIPT_DIR/rstudio_server_${PACKAGE_VERSION}.patch


cd ${TMPWS_DIR}/rstudio

# install dependencies
cd ./dependencies/linux
sed -i 's/sudo yum install -y openssl-devel/#sudo yum install -y openssl-devel/' ./install-dependencies-yum
sed -i 's/sudo yum install -y fakeroot/#sudo yum install -y fakeroot/' ./install-dependencies-yum

cd ${TMPWS_DIR}/rstudio

cd dependencies/common
sed -i '45 a "Linux-ppc64le") NODE_FILE="node-v${NODE_VERSION}-linux-ppc64le" ;; ' ./install-node
sed -i '42s/.*/export NODE_BASE_URL=https:\/\/nodejs.org\/dist\/v${NODE_VERSION}\//' ./install-npm-dependencies
sed -i '61 a cp ${NODE_SUBDIR}/bin/node /usr/bin/ ' ./install-npm-dependencies
sed -i 's/\.\/install-sentry-cli/#\.\/install-sentry-cli/' ./install-common

cd ..
cd linux
RSTUDIO_DISABLE_CRASHPAD=1  ./install-dependencies-yum
#unset R_HOME                   # while building with the base image of R
cd ../../
mkdir build && cd build

cd ${TMPWS_DIR}/rstudio/build

cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_INSTALL_PREFIX=/usr/lib/rstudio-server -DCMAKE_BUILD_TYPE=Release -DQUARTO_ENABLED=False

cd ${TMPWS_DIR}/rstudio/src/gwt/lib/quarto
sed -i '23 s/turbo/turbo-linux-ppc64le/' package.json
sed -i '23 s/\^1.8.5/1.4.7/'  package.json

export JAVA_HOME=/etc/alternatives/java_sdk_1.8.0
cd ${TMPWS_DIR}/rstudio/build

if ! PATH=${TMPWS_DIR}/rstudio/dependencies/common/node/18.18.2/bin:$PATH make install; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
fi


#package RStudio server
cd ${TMPWS_DIR}
tar czf rstudio_server_${ARCH}_${PACKAGE_VERSION}.tar.gz /usr/lib/rstudio-server

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
cd ${TMPWS_DIR}

if ! (rstudio-server start); then
    echo "------------------$PACKAGE_NAME:start_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Start_Fails"
    exit 1
fi


cd ${TMPWS_DIR}/rstudio/src/gwt
sed -i "412i\         \<jvmarg value='"-Xms16m"'/>" build.xml
sed -i "413i\         \<jvmarg value='"-Xmx1536m"'/>" build.xml

if ! (cd ${TMPWS_DIR}/rstudio/build/src/gwt && ./gwt-unit-tests.sh); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
fi

cd ${TMPWS_DIR}/rstudio/build/src/
chown rstudio: cpp

cd ${TMPWS_DIR}/rstudio/src/cpp/tests/testthat/
chown rstudio: themes

if ! (cd ${TMPWS_DIR}/rstudio/build/src/cpp && ./rstudio-tests --scope core); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
fi

if ! sudo -E -u rstudio bash -c "set -xe; cd \/tmp/rstudio/build/src/cpp &&  ./rstudio-tests --scope r"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
fi

if ! sudo -E -u rstudio bash -c "cd \/tmp/rstudio/build/src/cpp &&  ./rstudio-tests --scope rsession"; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
fi

sudo -E -u root bash -c 'bash << EOF
#cleanup
yum remove -y openssl-devel libsqlite3x-devel libsecret-devel
echo "Done building RStudio server"
EOF'
exit 0
