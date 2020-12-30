# ----------------------------------------------------------------------------
#
# Package        : KUI
# Version        : v8.12.2
# Source repo    : https://github.com/IBM/kui
# Tested on      : RHEL 8.2
# Script License : Apache License, Version 2 or later
# Maintainer     : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

set -eux

CWD=`pwd`

dnf -y --disableplugin=subscription-manager install \
    http://mirror.centos.org/centos/8.2.2004/BaseOS/ppc64le/os/Packages/centos-repos-8.2-2.2004.0.1.el8.ppc64le.rpm \
    http://mirror.centos.org/centos/8.2.2004/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8.2-2.2004.0.1.el8.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

# Install dependencies
yum install -y dnf
dnf install -y --allowerasing wget python2 bzip2 tar pkgconfig atk-devel alsa-lib-devel bison binutils bzip2-devel cairo-devel cups-devel dbus-devel dbus-glib-devel expat-devel fontconfig-devel freetype-devel gcc-c++ glib2-devel glibc gtk3-devel java-1.*.0-openjdk-devel libatomic libcap-devel libffi-devel libgcc libjpeg-devel libstdc++ libX11-devel libXScrnSaver-devel libXtst-devel ncurses-devel ncurses-libs nspr-devel nss-devel pam-devel pango-devel pciutils-devel pulseaudio-libs-devel zlib httpd mod_ssl php php-cli xorg-x11-server-Xvfb vim cmake3 krb5-devel subversion curl libuuid-devel libva-devel ccache xz patch diffutils findutils coreutils elfutils rpm-devel rpm rpm-build fakeroot libXcomposite gdk-pixbuf2-devel libnotify-devel lsof python38 git brlapi libxkbcommon-x11 python2-psutil python38-psutil mesa-libgbm libsecret-devel bluez-libs make

dnf install -y http://mirror.centos.org/centos/8.2.2004/PowerTools/ppc64le/os/Packages/brlapi-devel-0.6.7-28.el8.ppc64le.rpm
dnf install -y http://mirror.centos.org/centos/8.2.2004/PowerTools/ppc64le/os/Packages/bluez-libs-devel-5.50-3.el8.ppc64le.rpm
dnf install -y http://mirror.centos.org/centos/8.2.2004/PowerTools/ppc64le/os/Packages/gperf-3.1-5.el8.ppc64le.rpm
dnf install -y http://mirror.centos.org/centos/8.2.2004/PowerTools/ppc64le/os/Packages/libxkbcommon-x11-devel-0.9.1-1.el8.ppc64le.rpm
dnf install -y https://dl.fedoraproject.org/pub/epel/7/ppc64le/Packages/w/wdiff-1.2.2-3.el7.ppc64le.rpm
dnf install -y http://mirror.centos.org/centos/8.2.2004/PowerTools/ppc64le/os/Packages/re2c-0.14.3-2.el8.ppc64le.rpm
dnf install -y http://mirror.centos.org/centos/8.2.2004/PowerTools/ppc64le/os/Packages/ninja-build-1.8.2-1.el8.ppc64le.rpm
dnf install -y http://mirror.centos.org/centos/8.2.2004/PowerTools/ppc64le/os/Packages/mesa-libgbm-devel-19.3.4-2.el8.ppc64le.rpm

alternatives --set python /usr/bin/python2

VERSION=v12.16.1
DISTRO=linux-ppc64le

wget "https://nodejs.org/dist/$VERSION/node-$VERSION-$DISTRO.tar.xz"
tar -xJvf node-$VERSION-$DISTRO.tar.xz --no-same-owner
PATH=$CWD/node-$VERSION-$DISTRO/bin:$PATH

export CC=gcc
export CXX=g++

git clone https://gn.googlesource.com/gn
cd gn
git checkout 81ee1967d3fcbc829bac1c005c3da59739c88df9
sed -i '/-static-libstdc++/d' build/gen.py
python build/gen.py
ninja -C out

cd $CWD

export DEPOT_TOOLS_GN="$CWD/gn/out/gn"

git clone https://github.com/leo-lb/depot_tools
git -C depot_tools checkout ppc64le

export DEPOT_TOOLS_UPDATE=0
export PATH=$CWD/gn/out:$PATH:$CWD/depot_tools
export VPYTHON_BYPASS="manually managed python not supported by chrome operations"
export GYP_DEFINES="disable_nacl=1"

mkdir -p electron-gn && cd electron-gn
git --version
gclient config --name "src/electron" --unmanaged https://github.com/leo-lb/electron@7-2-x
gclient sync --with_branch_heads --with_tags --no-history

REVISION=$(grep -Po "(?<=CLANG_REVISION = ')\w+(?=')" src/tools/clang/scripts/update.py | head -n 1)

if [ -d "llvm-project" ]; then
    cd llvm-project
    git add -A
    git status
    git reset --hard HEAD
    git fetch
    git status
    cd ../
else
    git clone https://github.com/llvm/llvm-project.git
fi

git -C llvm-project checkout "${REVISION}"

mkdir -p llvm_build
cd llvm_build

LLVM_BUILD_DIR=$(pwd)

cmake -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="PowerPC" -DLLVM_ENABLE_PROJECTS="clang;lld" -G "Ninja" ../llvm-project/llvm
ninja -j$(nproc)

export PATH=$LLVM_BUILD_DIR/bin/:$PATH

cd ../src

export CC=clang
export CXX=clang++

cd third_party/libvpx
mkdir -p source/config/linux/ppc64
./generate_gni.sh
cd ../../

cd third_party/ffmpeg
./chromium/scripts/build_ffmpeg.py linux ppc64
./chromium/scripts/generate_gn.py
./chromium/scripts/copy_config.sh
cd ../../

gn gen out/Release --args="import(\"//electron/build/args/release.gn\") clang_base_path = \"$LLVM_BUILD_DIR\" use_glib=true use_gnome_keyring=false"
ninja -C out/Release electron
electron/script/strip-binaries.py -d out/Release
ninja -C out/Release electron:electron_dist_zip
ninja -C out/Release electron:electron_chromedriver_zip
echo "Distributable zip files located at: $(pwd)/out/Release/dist.zip $(pwd)/out/Release/chromedriver.zip"

cd out/Release
cp chromedriver.zip chromedriver-v7.0.0-linux-ppc64.zip
cp dist.zip electron-v7.3.1-linux-ppc64.zip
sha256sum -b chromedriver-v7.0.0-linux-ppc64.zip > SHASUMS256.txt
sha256sum -b electron-v7.3.1-linux-ppc64.zip >> SHASUMS256.txt
cd ..
# start http server which will serve the zips for KUI build
python3 -m http.server &
HTTP_SERVER_PID=$!

export CC=gcc
export CXX=g++

cd $CWD

git clone https://github.com/IBM/kui.git
cd kui
git checkout tags/v8.12.2
sed -i 's/"open": "electron . shell",/"open": "electron . shell --no-sandbox",/g' package.json
sed -i 's/"pty:rebuild": "kui-pty-rebuild",/"pty:rebuild": "cp packages\/builder\/npmrc node_modules\/node-pty-prebuilt-multiarch\/.npmrc \&\& cd node_modules\/node-pty-prebuilt-multiarch \&\& npm run install",/1' package.json
export ELECTRON_MIRROR="http://0.0.0.0:8000/"
export ELECTRON_CUSTOM_DIR="Release"
npm ci
npm rebuild node-sass && npm run compile
npm run pty:rebuild
kill -9 $HTTP_SERVER_PID
echo "KUI build successful."
echo "Building KUI proxy images based on UBI 8 minimal."
yes | cp $CWD/Dockerfile_ubi8-minimal packages/proxy/Dockerfile
npx kui-build-webpack
npx kui-build-docker-with-proxy
echo "Image built successfully. Build finished!"

