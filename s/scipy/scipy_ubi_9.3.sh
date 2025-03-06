#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : scipy
# Version           : v1.14.1
# Source repo       : https://github.com/scipy/scipy.git
# Tested on         : UBI:9.3
# Language          : Python
# Travis-Check      : True
# Script License    : Apache License, Version 2.0
# Maintainer        : Md. Shafi Hussain <Md.Shafi.Hussain@ibm.com>
#
# Disclaimer        : This script has been tested in root mode on given
# ==========          platform using the mentioned version of the package.
#                     It may not work as expected with newer versions of the
#                     package and/or distribution. In such case, please
#                     contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scipy
PACKAGE_URL=https://github.com/scipy/scipy.git

PACKAGE_VERSION=${1:-v1.10.1}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

MAX_JOBS=${MAX_JOBS:-$(nproc)}

WORKDIR=$(pwd)

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
    https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    git gcc-toolset-13 lapack-devel pkgconfig swig suitesparse-devel \
    python$PYTHON_VERSION-devel \
    python$PYTHON_VERSION-wheel \
    python$PYTHON_VERSION-pip \
    python$PYTHON_VERSION-setuptools

source /opt/rh/gcc-toolset-13/enable
curl -sL https://ftp2.osuosl.org/pub/ppc64el/openblas/latest/Openblas_0.3.29_ppc64le.tar.gz | tar xvf - -C /usr/local \
&& export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig/

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib

if [ -z $PACKAGE_SOURCE_DIR ]; then
    git clone $PACKAGE_URL -b $PACKAGE_VERSION
    cd $PACKAGE_NAME
    WORKDIR=$(pwd)
else
    WORKDIR=$PACKAGE_SOURCE_DIR
    cd $WORKDIR
    git checkout $PACKAGE_VERSION
fi

git submodule sync
git submodule update --init --recursive

# no venv - helps with meson build conflicts #
rm -rf $WORKDIR/PY_PRIORITY
mkdir $WORKDIR/PY_PRIORITY
PATH=$WORKDIR/PY_PRIORITY:$PATH
ln -sf $(command -v python$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/python
ln -sf $(command -v python$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/python3
ln -sf $(command -v python$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/python$PYTHON_VERSION
ln -sf $(command -v pip$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/pip
ln -sf $(command -v pip$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/pip3
ln -sf $(command -v pip$PYTHON_VERSION) $WORKDIR/PY_PRIORITY/pip$PYTHON_VERSION
##############################################

# issue: https://github.com/scipy/scipy/issues/21100#issuecomment-2538514333
if [[ $PACKAGE_VERSION == "v1.10.1" ]] && [[ $(git diff pyproject.toml | wc -l) -eq 0 ]]; then
    sed -i \
	-e 's/"pythran>=0.12.0,<0.13.0"/"pythran==0.12.1"/g' \
	-e '/"pythran==0.12.1",/a "pyproject_metadata==0.8.1",' \
	-e '/"pythran==0.12.1",/a "gast==0.5.0",' \
	-e '/"pythran==0.12.1",/a "beniget==0.4.0",' pyproject.toml
fi
###################################################################
if ! python -m pip install -vvv . $BUILD_ISOLATION; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

python -m pip install pytest pytest-xdist hypothesis

if [[ $PACKAGE_VERSION == "v1.10.1" ]]; then
    TEST_RC=$(python runtests.py --no-build -j $MAX_JOBS -s ndimage)
else
    cd /tmp
    TEST_RC=$(python -c "from scipy import cluster; cluster.test()")
fi

if [[ $TEST_RC -ne 0 ]]; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
