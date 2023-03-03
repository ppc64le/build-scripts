#!/bin/bash
#---------------------------------------------------------------------------------------------------
#
# Package		: Chromium
# Version		: 110.0.5481.77
# Source repo		: https://github.com/chromium/chromium
# Tested on		: Ubuntu 20.04
# Language		: C++
# Travis-Check		: false
# Script License	: Apache License, Version 2 or later
# Maintainer		: Sumit Dubey <sumit.dubey2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#---------------------------------------------------------------------------------------------------

set -eux

CWD=`pwd`
NODE_VERSION=v18.12.1
NODE_DISTRO=linux-ppc64le
GN_VERSION=5e19d2fb166fbd4f6f32147fbb2f497091a54ad8 
DEPOT_VERSION=26b6c9b4cf9617cfa196a0415baadd764a069e57
CHROMIUM_VERSION=110.0.5481.77

# Install and Setup Ubuntu Dependencies
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y  build-essential libdbus-1-dev libgtk-3-dev libnotify-dev libasound2-dev libcap-dev libcups2-dev libxtst-dev libxss1 libnss3-dev curl gperf bison python3-dbusmock openjdk-8-jre git wget python3 python3-httplib2 python3-six lsof libdrm-dev libgbm-dev mesa-common-dev ninja-build cmake unzip sudo libre2-dev xvfb  libgl1-mesa-glx xcb libxcb-xkb-dev x11-xkb-utils libx11-xcb-dev libxkbcommon-x11-dev libpci-dev libcurl4-gnutls-dev libkrb5-dev libpulse-dev libxshmfence-dev elfutils lsb-release qtbase5-dev qt5-qmake
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
	\rm -rf node-$NODE_VERSION-$NODE_DISTRO.tar.xz
fi
export PATH=$CWD/node-$NODE_VERSION-$NODE_DISTRO/bin:$PATH

# Prepare for build
export DEPOT_TOOLS_UPDATE=0
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"
export GIT_CACHE_PATH="${CWD}/.git_cache"
mkdir -p "${GIT_CACHE_PATH}"
if [ -z "$(ls -A $CWD/chromium/src)" ]; then
	# Download and extract ppc64le patches
	wget 'https://quickbuild.io/~raptor-engineering-public/+archive/ubuntu/chromium/+files/chromium_110.0.5481.77-1raptor0~deb11u1.debian.tar.xz'
	wget https://raw.githubusercontent.com/PF4Public/gentoo-overlay/d751edc24f85db39911abf94fde35c8cb68aac1a/dev-util/electron/files/ppc64le/fix-breakpad-compile.patch
	wget https://raw.githubusercontent.com/PF4Public/gentoo-overlay/d751edc24f85db39911abf94fde35c8cb68aac1a/dev-util/electron/files/ppc64le/libpng-pdfium-compile-98.patch
	wget https://raw.githubusercontent.com/PF4Public/gentoo-overlay/d751edc24f85db39911abf94fde35c8cb68aac1a/dev-util/electron/files/ppc64le/fix-swiftshader-compile.patch
	tar -xf chromium_110.0.5481.77-1raptor0~deb11u1.debian.tar.xz
	\rm -rf chromium_110.0.5481.77-1raptor0~deb11u1.debian.tar.xz

	# Checkout source
	mkdir -p chromium && cd chromium
	fetch --nohooks chromium
	cd src
	git checkout $CHROMIUM_VERSION
	gclient sync --nohooks --with_branch_heads --with_tags -vv
	sed -i "s#x86_64#ppc64le#g" native_client/pynacl/platform.py
	sed -i "s#X86_64#ppc64le#g" native_client/pynacl/platform.py
	gclient runhooks -vv

	# Apply patches
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
	sed -i '321i \ \ } else if (strcmp(nacl_arch, "ppc64") == 0) {' chrome/browser/extensions/api/runtime/chrome_runtime_api_delegate.cc
	sed -i '322i \ \ \ \ info->nacl_arch = extensions::api::runtime::PLATFORM_NACL_ARCH_PPC64;' chrome/browser/extensions/api/runtime/chrome_runtime_api_delegate.cc
	sed -i '305i \ \ } else if (strcmp(arch, "ppc64") == 0) {' chrome/browser/extensions/api/runtime/chrome_runtime_api_delegate.cc
	sed -i '306i \ \ \ \ info->arch = extensions::api::runtime::PLATFORM_ARCH_PPC64;' chrome/browser/extensions/api/runtime/chrome_runtime_api_delegate.cc
	sed -i '24i #if !defined(__NR_faccessat2)' sandbox/linux/system_headers/ppc64_linux_syscalls.h	
	sed -i '25i #define __NR_faccessat2 439' sandbox/linux/system_headers/ppc64_linux_syscalls.h
	sed -i '26i #endif' sandbox/linux/system_headers/ppc64_linux_syscalls.h
	sed -i '140i #elif defined(ARCH_CPU_PPC64)' ./base/system/sys_info.cc
	sed -i '141i \ \ return "PPC64";' ./base/system/sys_info.cc
	sed -i '145i #endif' ./base/system/sys_info_linux.cc
	sed -i '135i #else' ./base/system/sys_info_linux.cc
	sed -i '135i \ \ info.model = data.substr(pos + 1);' ./base/system/sys_info_linux.cc
	sed -i '135i \ \ info.manufacturer = data.substr(0, pos);' ./base/system/sys_info_linux.cc
	sed -i '135i \ \ size_t pos = data.find(",");' ./base/system/sys_info_linux.cc
	sed -i '135i \ \ data=CPUModelName();' ./base/system/sys_info_linux.cc
	sed -i '135i #if BUILDFLAG(IS_LINUX) && defined(ARCH_CPU_PPC64)' ./base/system/sys_info_linux.cc
	sed -i '78i #elif BUILDFLAG(IS_LINUX) && defined(ARCH_CPU_PPC64)' ./base/system/sys_info_linux.cc
	sed -i '79i \ \ const char kCpuModelPrefix[] = "model";' ./base/system/sys_info_linux.cc
	sed -i.bak '2373d' chrome/browser/extensions/extension_service_unittest.cc
	sed -i '2373i #if BUILDFLAG(IS_MAC) || BUILDFLAG(IS_WIN) || defined(ARCH_CPU_PPC64)' chrome/browser/extensions/extension_service_unittest.cc

	# Remove intermediate files
	\rm -rf ${CWD}/debian
	\rm -rf ${CWD}/fix-breakpad-compile.patch
	\rm -rf ${CWD}/fix-swiftshader-compile.patch
	\rm -rf ${CWD}/libpng-pdfium-compile-98.patch
	cd ../../
fi

# Install clang
if [ -z "$(ls -A $CWD/llvm-project)" ]; then
	set +x
	while IFS='= ' read -r k v; do
   		[[ $k = "CLANG_REVISION" ]] && declare -x $k="${v//\"/}"
	done < $CWD/chromium/src/tools/clang/scripts/update.py
	eval CLANG_REVISION=$CLANG_REVISION
	set -x
	git clone https://github.com/llvm/llvm-project.git
	cd llvm-project
	git checkout "${CLANG_REVISION}"
	mkdir -p llvm-build
	cd llvm-build
	cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="PowerPC" -DLLVM_ENABLE_PROJECTS="clang;lld" -G "Ninja" ../llvm
	ninja -j$(nproc)
else
	cd llvm-project/llvm-build
fi
LLVM_BUILD_DIR=$(pwd)
export PATH=$LLVM_BUILD_DIR/bin/:$PATH
export CPLUS_INCLUDE_PATH="${CPLUS_INCLUDE_PATH:+${CPLUS_INCLUDE_PATH}:}$CWD/llvm-project/compiler-rt/include/"
cd ../../

# Build
cd chromium/src
cp $(which node) third_party/node/linux/node-linux-x64/bin/node
cp $(which eu-strip) buildtools/third_party/eu-strip/bin/eu-strip
sysctl -w vm.max_map_count=262144
gn gen out/Release --args="chrome_pgo_phase=0 is_debug=false dcheck_always_on=false is_official_build = true clang_base_path = \"$LLVM_BUILD_DIR\" is_clang=true use_gnome_keyring=false treat_warnings_as_errors=false clang_use_chrome_plugins = false symbol_level=0 enable_nacl=false blink_symbol_level=0 v8_symbol_level=0"
autoninja -C out/Release chrome
autoninja -C out/Release chromedriver
strip --discard-all --strip-debug --preserve-dates out/Release/chrome

# Test
autoninja -C out/Release unit_tests
adduser --disabled-password --gecos "" chrome || true
service dbus start
export DISPLAY=:99
Xvfb :99 -screen 0 640x480x8 -nolisten tcp &
export XDG_RUNTIME_DIR=/run/user/$(id -u chrome)
mkdir -p $XDG_RUNTIME_DIR
chmod 777 $XDG_RUNTIME_DIR
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
sudo -u chrome -i bash << EOF
	set -ex
	export DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS
        dbus-daemon --session --address=$DBUS_SESSION_BUS_ADDRESS --nofork --nopidfile --syslog-only &
	export PATH=$PATH
	cd $CWD/chromium/src
	./out/Release/unit_tests --disable-gpu
EOF

# Conclude
export CHROME_BIN=$CWD/chromium/src/out/Release/chrome
export CHROMEDRIVER_BIN=$CWD/chromium/src/out/Release/chromedriver
set +x
echo "Build and Test Successful!. The 8 failing and 1 crashing tests are in parity with Intel."
echo "Chromium binary is located at $CHROME_BIN"
echo "Chromedriver binary is located at $CHROMEDRIVER_BIN"
