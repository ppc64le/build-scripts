#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : rstudio
# Version       : v2025.09.0+387
# Source repo   : https://github.com/rstudio/rstudio.git
# Tested on     : ubuntu_22.04
# Language      : Java,C++
# Ci-Check      : False
# Script License: Apache License Version 2.0
# Maintainer    : Veenious D Geevarghese <Veenious.Geevarghese@ibm.com>
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
PACKAGE_VERSION=${1:-v2025.09.0+387}
PREFIX_DIR=/usr/lib/rstudio-server
TMPWS_DIR=/tmp
RSTUDIO_TOOLS_ROOT=${RSTUDIO_TOOLS_ROOT:-/opt/rstudio-tools/$(uname -m)}
NODE_VERSION=20.20.0
export RSTUDIO_VERSION_MAJOR=2025
export RSTUDIO_VERSION_MINOR=09
export RSTUDIO_VERSION_PATCH=0
export RSTUDIO_VERSION_SUFFIX="+387"
export DEBIAN_FRONTEND=noninteractive
export CFLAGS="${CFLAGS:-} -maltivec -mvsx"
export CXXFLAGS="${CXXFLAGS:-} -maltivec -mvsx"
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-ppc64el
export PATH=$JAVA_HOME/bin:$PATH

cd ${TMPWS_DIR}
rm -rf ${PACKAGE_NAME}

# ----------------------------------------------------------------------------
#installing dependencies
# ----------------------------------------------------------------------------

apt-get update -y
apt-get install -y \
  sudo ca-certificates curl wget git git-lfs gnupg \
  build-essential pkg-config cmake ninja-build \
  python3 python3-dev python3-venv python3-pip python3-setuptools python3-wheel \
  ant openjdk-17-jdk \
  rsync unzip xz-utils zip \
  patchelf dpkg-dev lsb-release \
  libssl-dev zlib1g-dev libcurl4-openssl-dev \
  libxml2-dev libxslt1-dev \
  libsqlite3-dev libpq-dev \
  libsecret-1-dev libglib2.0-dev \
  libpam0g-dev libedit-dev uuid-dev \
  r-base r-base-dev \
  pandoc \
  lsof

mkdir -p /opt/nodejs
curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-ppc64le.tar.xz \
  | tar -xJ -C /opt/nodejs
export PATH=/opt/nodejs/node-v${NODE_VERSION}-linux-ppc64le/bin:$PATH

# ----------------------------------------------------------------------------
# Clone
# ----------------------------------------------------------------------------
git clone --recursive ${PACKAGE_URL} ${PACKAGE_NAME}
cd ${TMPWS_DIR}/${PACKAGE_NAME}
git checkout ${PACKAGE_VERSION}
git lfs install --local || true
git lfs pull || true
PATCH_FILE="rstudio_server_${PACKAGE_VERSION}.patch"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/r/rstudio/${PATCH_FILE}
git apply ${PATCH_FILE}

# ---------------------------------------------------------------------------
# create the i18n-helpers venv where install-dependencies expects it
# ---------------------------------------------------------------------------
python3 -m venv src/gwt/tools/i18n-helpers/VENV
src/gwt/tools/i18n-helpers/VENV/bin/pip install -U pip setuptools wheel >/dev/null

# ---------------------------------------------------------------------------
# patch Copilot language server installer
# ---------------------------------------------------------------------------
printf '#!/usr/bin/env bash\necho "Copilot disabled on ppc64le"; exit 0\n' > dependencies/common/install-copilot-language-server
chmod +x dependencies/common/install-copilot-language-server

# ---------------------------------------------------------------------------
# Run upstream dependency installers (Ubuntu 22.04)
# ---------------------------------------------------------------------------
( cd dependencies/linux && bash ./install-dependencies-jammy )

# ---------------------------------------------------------------------------
# Stage gwt-rstudio SDK
# ---------------------------------------------------------------------------
mkdir -p src/gwt/lib/gwt
ln -sfn "$(pwd)/dependencies/common/gwtproject/gwt/gwt-rstudio" \
       src/gwt/lib/gwt/gwt-rstudio

[ -f src/gwt/lib/gwt/gwt-rstudio/gwt-user.jar ] || \
  { echo "[!] gwt-user.jar not found"; exit 1; }

# ----------------------------------------------------------------------------
# Configure + build + install
# ----------------------------------------------------------------------------
rm -rf build
mkdir build && cd build

cmake .. \
  -DRSTUDIO_TARGET=Server \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=${PREFIX_DIR} \
  -DQUARTO_ENABLED=OFF \
  -DRSTUDIO_ENABLE_COPILOT=OFF \
  -DRSTUDIO_CRASHPAD_ENABLED=OFF \
  -DCMAKE_CXX_FLAGS="-DRSTUDIO_BOOST_NAMESPACE=rstudio_boost" \
  -DRSTUDIO_TOOLS_ROOT=${RSTUDIO_TOOLS_ROOT} \
  -DRSTUDIO_VERSION_MAJOR=${RSTUDIO_VERSION_MAJOR} \
  -DRSTUDIO_VERSION_MINOR=${RSTUDIO_VERSION_MINOR} \
  -DRSTUDIO_VERSION_PATCH=${RSTUDIO_VERSION_PATCH} \
  -DRSTUDIO_VERSION_SUFFIX=${RSTUDIO_VERSION_SUFFIX}

cmake --build . --target install -- -j"$(nproc)"

# ----------------------------------------------------------------------------
# Unit tests
# ----------------------------------------------------------------------------
cd ${TMPWS_DIR}/${PACKAGE_NAME}
if [ -d src/gwt ]; then
  (cd src/gwt && ant unittest) || {
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
  }
fi

[ -x build/src/cpp/rstudio-tests ] || {
  echo "[!] rstudio-tests binary not found at build/src/cpp/rstudio-tests" >&2
  exit 2
}

id -u rstudio >/dev/null 2>&1 || useradd -m -s /bin/bash rstudio
chown -R rstudio:rstudio "${TMPWS_DIR}/${PACKAGE_NAME}" || true

cd build/src/cpp
./rstudio-tests --scope core || exit 2
./rstudio-tests --scope rserver || exit 2
sudo -u rstudio env LANG=C.UTF-8 LC_ALL=C.UTF-8 ./rstudio-tests --scope r || exit 2
sudo -u rstudio env LANG=C.UTF-8 LC_ALL=C.UTF-8 ./rstudio-tests --scope rsession || exit 2

echo "------------------${PACKAGE_NAME}:install_&_test_both_success-------------------------"
echo "${PACKAGE_URL} ${PACKAGE_NAME}"
echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Pass | Both_Install_and_Test_Success"
echo "[OK] Installed to: ${PREFIX_DIR}"
exit 0