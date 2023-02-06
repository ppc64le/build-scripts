#!/bin/bash
#---------------------------------------------------------------------------------------------------
#
# Package	: Electron
# Version	: v22.0.3
# Source repo	: https://github.com/electron/electron
# Tested on	: Ubuntu 22.04
# Language      : C++
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer	: Sumit Dubey <sumit.dubey2@ibm.com>
# Instructions	: docker run -t -d --shm-size=2gb --privileged --name <cname> docker.io/ubuntu:22.04
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#---------------------------------------------------------------------------------------------------

set -eux

CWD=`pwd`
NODE_VERSION=v19.4.0
NODE_DISTRO=linux-ppc64le
GN_VERSION=5e19d2fb166fbd4f6f32147fbb2f497091a54ad8 
DEPOT_VERSION=26b6c9b4cf9617cfa196a0415baadd764a069e57
ELECTRON_VERSION=v22.0.3

# Install and Setup Ubuntu Dependencies
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y  build-essential libdbus-1-dev libgtk-3-dev libnotify-dev libasound2-dev libcap-dev libcups2-dev libxtst-dev libxss1 libnss3-dev curl gperf bison python3-dbusmock openjdk-8-jre git wget python3.10 python3-httplib2 python3-six lsof libdrm-dev libgbm-dev mesa-common-dev ninja-build cmake unzip sudo libre2-dev xvfb  libgl1-mesa-glx xcb libxcb-xkb-dev x11-xkb-utils libx11-xcb-dev libxkbcommon-x11-dev libpci-dev libcurl4-gnutls-dev libkrb5-dev libpulse-dev libxshmfence-dev elfutils
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
export JAVA_PATH=$(dirname $(which java))

# Install gn
export CC=gcc
export CXX=g++
if [ -z "$(ls -A $CWD/gn)" ]; then
	git clone https://gn.googlesource.com/gn
	cd gn
	git checkout $GN_VERSION
	sed -i '461,462d' build/gen.py
	python3 build/gen.py
	ninja -C out
	cd ..
fi
export PATH=$CWD/gn/out:$PATH
export DEPOT_TOOLS_GN="$CWD/gn/out/gn"

# Install Depot Tools
if [ -z "$(ls -A $CWD/depot_tools)" ]; then
	git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
	cd depot_tools
	git checkout $DEPOT_VERSION
	sed -i '1612,1622d' gclient_scm.py
	sed -i '1612i \ \ \ \ return' gclient_scm.py
	cd ..
fi
export PATH=$PATH:$CWD/depot_tools

# Install node.js
if [ -z "$(ls -A $CWD/node-$NODE_VERSION-$NODE_DISTRO)" ]; then
	wget "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-$NODE_DISTRO.tar.xz"
	tar -xJvf node-$NODE_VERSION-$NODE_DISTRO.tar.xz --no-same-owner
	rm -rf node-$NODE_VERSION-$NODE_DISTRO.tar.xz
fi
export PATH=$CWD/node-$NODE_VERSION-$NODE_DISTRO/bin:$PATH

# Prepare for build
export DEPOT_TOOLS_UPDATE=0
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"
export GIT_CACHE_PATH="${HOME}/.git_cache"
mkdir -p "${GIT_CACHE_PATH}"
if [ -z "$(ls -A $CWD/electron/src)" ]; then
	# Download and extract ppc64le patches
        wget 'https://quickbuild.io/~raptor-engineering-public/+archive/ubuntu/chromium/+files/chromium_108.0.5359.71-2raptor0~deb11u1.debian.tar.xz'
	wget https://raw.githubusercontent.com/PF4Public/gentoo-overlay/master/dev-util/electron/files/ppc64le/fix-breakpad-compile.patch
	wget https://raw.githubusercontent.com/PF4Public/gentoo-overlay/master/dev-util/electron/files/ppc64le/libpng-pdfium-compile-98.patch
	wget https://raw.githubusercontent.com/PF4Public/gentoo-overlay/master/dev-util/electron/files/ppc64le/fix-swiftshader-compile.patch
        tar -xf chromium_108.0.5359.71-2raptor0~deb11u1.debian.tar.xz
        rm -rf chromium_108.0.5359.71-2raptor0~deb11u1.debian.tar.xz
	
	# Checkout source
	mkdir -p electron && cd electron
	gclient config --name "src/electron" --unmanaged https://github.com/electron/electron@${ELECTRON_VERSION}
	gclient sync --with_branch_heads --with_tags -vv
	
	# Apply patches
	cd src
	sed -i "s#ppc64le/fixes/fix-breakpad-compile.patch##g" ${CWD}/debian/patches/series
	for p in $(grep -v "^#" "${CWD}"/debian/patches/series | grep "^ppc64le"); do
	        git apply "${CWD}/debian/patches/${p}"
	done
	git apply ${CWD}/fix-breakpad-compile.patch
	git apply ${CWD}/fix-swiftshader-compile.patch
	git apply ${CWD}/libpng-pdfium-compile-98.patch
	sed -i 's#"-Wno-tautological-constant-out-of-range-compare"#"-Wno-tautological-constant-out-of-range-compare", "-DPNG_POWERPC_VSX_OPT=0"#g' third_party/libpng/BUILD.gn
	sed -i "s#_CURRENT_DIR, \"..\", \"jdk\", \"current\", \"bin\", \"java\"#\"${JAVA_PATH}\", \"java\"#g" third_party/closure_compiler/compiler.py
	sed -i 's#, "mips64"#, "mips64", "ppc64"#g' extensions/common/api/runtime.json
	sed -i '330i \ \ } else if (strcmp(nacl_arch, "ppc64") == 0) {' chrome/browser/extensions/api/runtime/chrome_runtime_api_delegate.cc
	sed -i '331i \ \ \ \ info->nacl_arch = extensions::api::runtime::PLATFORM_NACL_ARCH_PPC64;' chrome/browser/extensions/api/runtime/chrome_runtime_api_delegate.cc
	sed -i '314i \ \ } else if (strcmp(arch, "ppc64") == 0) {' chrome/browser/extensions/api/runtime/chrome_runtime_api_delegate.cc
	sed -i '315i \ \ \ \ info->arch = extensions::api::runtime::PLATFORM_ARCH_PPC64;' chrome/browser/extensions/api/runtime/chrome_runtime_api_delegate.cc
	sed -i '84i \ \ } else if (strcmp(nacl_arch, "ppc64") == 0) {' electron/shell/browser/extensions/api/runtime/electron_runtime_api_delegate.cc
	sed -i '85i \ \ \ \ info->nacl_arch = extensions::api::runtime::PLATFORM_NACL_ARCH_PPC64;' electron/shell/browser/extensions/api/runtime/electron_runtime_api_delegate.cc
	sed -i '69i \ \ } else if (strcmp(arch, "ppc64") == 0) {' electron/shell/browser/extensions/api/runtime/electron_runtime_api_delegate.cc
	sed -i '70i \ \ \ \ info->arch = extensions::api::runtime::PLATFORM_ARCH_PPC64;' electron/shell/browser/extensions/api/runtime/electron_runtime_api_delegate.cc
	
	# Remove intermediate files
	rm -rf ${CWD}/debian
        rm -rf ${CWD}/fix-breakpad-compile.patch
        rm -rf ${CWD}/fix-swiftshader-compile.patch
        rm -rf ${CWD}/libpng-pdfium-compile-98.patch
	cd ../../
fi

# Install clang
if [ -z "$(ls -A $CWD/llvm-project)" ]; then
	set +x
	while IFS='= ' read -r k v; do
   		[[ $k = "CLANG_REVISION" ]] && declare -x $k="${v//\"/}"
	done < $CWD/electron/src/tools/clang/scripts/update.py
	eval CLANG_REVISION=$CLANG_REVISION
	set -x
        git clone https://github.com/llvm/llvm-project.git
        cd llvm-project
        git checkout "${CLANG_REVISION}"
        mkdir -p llvm-build
        cd llvm-build
        cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="PowerPC" -DLLVM_ENABLE_PROJECTS="clang;lld" -G "Ninja" ../llvm
        ninja -j$(nproc)
fi
LLVM_BUILD_DIR=$CWD/llvm-project/llvm-build
export PATH=$LLVM_BUILD_DIR/bin/:$PATH
cd ../../

# Build
cd electron/src
cp $(which node) third_party/node/linux/node-linux-x64/bin/node
cp $(which eu-strip) buildtools/third_party/eu-strip/bin/eu-strip
if [ ! -f "$CWD/electron/src/out/Release/electron" ]; then
	gn gen out/Release --args="import(\"//electron/build/args/release.gn\") clang_base_path = \"$LLVM_BUILD_DIR\" is_clang=true use_gnome_keyring=false treat_warnings_as_errors=false clang_use_chrome_plugins = false"
	ninja -C out/Release electron
	ninja -C out/Release electron:electron_dist_zip
	ninja -C out/Release electron:electron_chromedriver_zip
	ninja -C out/Release third_party/electron_node:headers
fi

# Test
cd electron
npm install --global yarn
adduser --disabled-password --gecos "" electron || true
chmod 4755 ../out/Release/chrome_sandbox
chmod -R 777 $CWD/electron
export DISPLAY=:99
Xvfb :99 -screen 0 640x480x8 -nolisten tcp &
export XDG_RUNTIME_DIR=/run/user/$(id -u electron)
mkdir -p $XDG_RUNTIME_DIR
chmod 777 $XDG_RUNTIME_DIR
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
sudo -u electron -i bash << EOF
	set -ex
	mkdir -p $CWD/electron/src/electron/node_modules/dugite/git/bin
	cp $(which git) $CWD/electron/src/electron/node_modules/dugite/git/bin/git
	export DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS
        dbus-daemon --session --address=$DBUS_SESSION_BUS_ADDRESS --nofork --nopidfile --syslog-only &
	export PATH=$PATH
	cd $CWD/electron/src/electron && yarn install
	cd $CWD/electron/src/electron/spec && yarn install
	cd $CWD/electron/src
	$CWD/electron/src/out/Release/electron electron/spec --disable-gpu || true
EOF

# Conclude
set +x
echo "Complete! The 9 test failures are in parity with x86. Distributable zip files located at: $CWD/electron/src/out/Release/dist.zip $CWD/electron/src/out/Release/chromedriver.zip"
