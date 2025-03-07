#!/bin/bash -e

# -----------------------------------------------------------------------------
#
# Package           : audio
# Version           : v2.5.1
# Source repo       : https://github.com/pytorch/audio.git
# Tested on         : UBI:9.3
# Language          : Python
# Travis-Check      : False
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

PACKAGE_NAME=audio
PACKAGE_URL=https://github.com/pytorch/audio.git

PACKAGE_VERSION=${1:-v2.5.1}
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

export MAX_JOBS=${MAX_JOBS:-$(nproc)}
export BUILD_SOX=${BUILD_SOX:-1}
export BUILD_KALDI=${BUILD_KALDI:-1}
export BUILD_RNNT=${BUILD_RNNT:-1}
# skip ffmpeg features
export USE_FFMPEG=${USE_FFMPEG:-0}
# disable ffmpeg tests
export TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_FFMPEG=${TORCHAUDIO_TEST_ALLOW_SKIP_IF_NO_FFMPEG:-1}
export USE_ROCM=${USE_ROCM:-0}
export USE_CUDA=${USE_CUDA:-0}
export _GLIBCXX_USE_CXX11_ABI=${_GLIBCXX_USE_CXX11_ABI:-1}

WORKDIR=$(pwd)

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

dnf install -y https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-9.0-24.el9.noarch.rpm \
    https://mirror.stream.centos.org/9-stream/BaseOS/`arch`/os/Packages/centos-stream-repos-9.0-24.el9.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/`arch`/os
dnf config-manager --set-enabled crb
dnf install -y git cmake ninja-build gcc-toolset-13 rust cargo jq sox-devel \
    python$PYTHON_VERSION-devel \
    python$PYTHON_VERSION-pip \
    python$PYTHON_VERSION-setuptools \
    python$PYTHON_VERSION-wheel

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


# Build Dependencies when BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then
    # dependencies for numpy
    dnf install -y lapack-devel pkgconfig

    # setup
    DEPS_DIR=$WORKDIR/deps_from_src
    rm -rf $DEPS_DIR
    mkdir -p $DEPS_DIR
    cd $DEPS_DIR
    

    # install dependency - pytorch
    PYTORCH_VERSION=${PYTORCH_VERSION:-$(curl -sSL https://api.github.com/repos/pytorch/pytorch/releases/latest | jq -r .tag_name)}

    git clone https://github.com/pytorch/pytorch.git
    cd pytorch
    git checkout tags/$PYTORCH_VERSION

    PPC64LE_PATCH="69cbf05"
    if ! git log --pretty=format:"%H" | grep -q "$PPC64LE_PATCH"; then
        echo "Applying POWER patch."
        git config user.email "Md.Shafi.Hussain@ibm.com"
        git config user.name "Md. Shafi Hussain"
        git cherry-pick "$PPC64LE_PATCH"
    else
        echo "POWER patch not needed."
    fi

    git submodule sync
    git submodule update --init --recursive
    python -m pip install -r requirements.txt
    python setup.py develop

    # cleanup
    rm -rf $DEPS_DIR
else
    python -m pip install -r requirements.txt
fi

cd $WORKDIR

# torchvision build setup
BUILD_ISOLATION=""
# When BUILD_DEPS is unset or set to True
if [ -z $BUILD_DEPS ] || [ $BUILD_DEPS == True ]; then
    BUILD_ISOLATION="--no-build-isolation"
fi

if ! (python -m pip install -v -e . $BUILD_ISOLATION --no-use-pep517); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

python -m pip install pytest pytest-xdist typing scipy numpy parameterized expecttest

if ! python -m pytest -n auto -xrfE test/torchaudio_unittest/sox_effect/ test/torchaudio_unittest/utils/ test/torchaudio_unittest/kaldi_io_test.py ; then
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
