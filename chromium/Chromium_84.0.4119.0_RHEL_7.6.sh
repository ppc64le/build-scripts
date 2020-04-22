# ----------------------------------------------------------------------------
#
# Package	: chromium
# Version	: 84.0.4119.0
# Source repo	: 
# Tested on	: RHEL 7.6
# Script License: Apache License Version 2.0
# Maintainer	: Lysanne Fernandes <lysannef@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash

set -ex

cd $HOME

# Install Dependencies
yum -y clean all
yum -y repolist

yum -y install git vim make cmake python cups-devel pkgconfig nss-devel openssl-devel glib2-devel libgnome-keyring-devel  pango-devel dbus-devel atk-devel at-spi2-atk-devel gtk3-devel krb5-devel pulseaudio-libs-devel libXScrnSaver-devel epel-release subversion curl alsa-lib-devel pciutils-devel mesa-libGLw gperf bison patch bzip2 uuid-devel mesa-libgbm.ppc64le mesa-libgbm-devel.ppc64le

yum -y install cmake3 re2c clang ninja-build
yum -y install java-1.8.0-openjdk-devel libXtst-devel devtoolset-7-libatomic-devel
yum -y install gcc gcc-c++

# Install nodejs
curl https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install v12.4.0
ln -s $HOME/.nvm/versions/node/v12.4.0/bin/node /usr/bin/node

# Install git 2.21.0
yum -y install curl-devel expat-devel gettext-devel zlib-devel
yum -y install perl-ExtUtils-MakeMaker wget

cd /usr/src
wget https://www.kernel.org/pub/software/scm/git/git-2.21.0.tar.gz
tar xzf git-2.21.0.tar.gz

cd git-2.21.0
make prefix=/usr/local/git all
make prefix=/usr/local/git install

echo "export PATH=/usr/local/git/bin:$PATH" >> /etc/bashrc
source /etc/bashrc

# Install GCC8
cd $HOME
wget https://ftp.gnu.org/gnu/gcc/gcc-8.2.0/gcc-8.2.0.tar.gz
tar xzf gcc-8.2.0.tar.gz
cd gcc-8.2.0
./contrib/download_prerequisites
cd ..
mkdir gcc-8.2.0-build
cd gcc-8.2.0-build
../gcc-8.2.0/configure --enable-languages=c,c++ --disable-multilib
make -j8
make install

export PATH=/usr/local/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH

# Remove Older gcc and create linkages to gcc8
yum -y remove gcc
ln -s /usr/local/bin/gcc /usr/bin/gcc
ln -s /usr/bin/gcc /usr/bin/cc
ln -s /usr/local/bin/g++ /usr/bin/g++
ln -s /usr/bin/g++ /usr/bin/c++

ln -s  /usr/local/lib/gcc/powerpc64le-unknown-linux-gnu/ /usr/lib/gcc/powerpc64le-unknown-linux-gnu

#check gcc version
#gcc --version

cd $HOME
mkdir chromium_build
export CHROMIUM_DIR=$HOME/chromium_build
cd $CHROMIUM_DIR

git clone https://gn.googlesource.com/gn
export CC=gcc
export CXX=g++
export AR=ar

cd gn/
git checkout 56f058e15884c81e6137bc5db506afb30e543e7e
python build/gen.py 
ninja-build -C out

unset CXX
unset CC
unset AR 

cd $CHROMIUM_DIR
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

echo 'export PATH="$PATH:${CHROMIUM_DIR}/gn/out"' >> env.sh
echo 'export PATH="$PATH:${CHROMIUM_DIR}/depot_tools"' >> env.sh
echo 'export VPYTHON_BYPASS="manually managed python not supported by chrome operations"' >> env.sh
source env.sh


# check out LLVM and Clang
export CLANG_REVISION=375507
cd $CHROMIUM_DIR
svn checkout --force https://llvm.org/svn/llvm-project/llvm/trunk@$CLANG_REVISION llvm
svn checkout --force https://llvm.org/svn/llvm-project/cfe/trunk@$CLANG_REVISION llvm/tools/clang
svn checkout --force https://llvm.org/svn/llvm-project/compiler-rt/trunk@$CLANG_REVISION llvm/compiler-rt 

# Build the compiler
mkdir llvm_build && cd llvm_build
cmake3 -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="PowerPC" -G "Unix Makefiles" ../llvm
make -j8

# Downloading the source code
cd $CHROMIUM_DIR
mkdir chromium && cd chromium
git clone  -b 84.0.4119.0 https://chromium.googlesource.com/chromium/src

# Pre-build
curl "https://wiki.raptorcs.com/w/images/1/10/Binutils-download.py-PPC.patch" | patch -p1 src/third_party/binutils/download.py
sed -i 's/\"custom_vars\"\: {},/\"custom_vars\"\: { \"checkout_nacl\"\: False },/g' .gclient

rm -rf src/buildtools/linux64/gn
cp -f $CHROMIUM_DIR/gn/out/gn src/buildtools/linux64/gn

gclient sync

# Patching Chromium
cd $CHROMIUM_DIR
git clone https://github.com/shawnanastasio/chromium_power
cd chromium_power
git checkout 146c60db1ac158ccb6397e3e74f7381b21a638c4

sed -i '/0001-Implement-support-for-PPC64-on-Linux.patch/d' patches.json
sed -i '/prompt_fail_action(e.reason, dest_dir, patch_path, e.output)/d' cpf.py
sed -i '/if not DRY and e.reason != PatchFailReason.ALREADY:/d' cpf.py

python3 cpf.py $CHROMIUM_DIR/chromium/src

cd $CHROMIUM_DIR/chromium/src/third_party/crashpad/crashpad/
cat ../../../../../chromium_power/crashpad/0001-Implement-support-for-PPC64-on-Linux.patch | patch -p1

cd $CHROMIUM_DIR/chromium/src/third_party/ffmpeg

# Install CLANG
cd $CHROMIUM_DIR/llvm_build/
make install 
cd -

# Generate ppc64le configuration files for libvpx and ffmpeg
./chromium/scripts/build_ffmpeg.py linux ppc64
./chromium/scripts/generate_gn.py
./chromium/scripts/copy_config.sh

cd $CHROMIUM_DIR/chromium/src/third_party/libvpx

mkdir source/config/linux/ppc64
./generate_gni.sh 
cd ../../ 

cd $CHROMIUM_DIR
yes | cp -f gn/out/gn chromium/src/buildtools/linux64/gn

cd $CHROMIUM_DIR/chromium/src

curl "https://wiki.raptorcs.com/w/images/b/bb/0001-sandbox-linux-seccomp-bpf-helpers-Fix-TCGETS-declara.patch" | patch -p1

# Configure build parameters with gn
mkdir out/Default
cd out/Default

echo '# Build arguments go here.
# See "gn args <out_dir> --list" for available build arguments.
# Release mode
is_component_build = false
is_debug = false
# Disable broken features
enable_nacl = false
treat_warnings_as_errors = false
enable_dav1d_decoder = false
# For clang, add the following lines:
is_clang = true
clang_base_path = "/root/chromium_build/llvm_build"
clang_use_chrome_plugins = false
use_lld = false' > args.gn 

cd ../../

#Additional patches for ppc for gn gen failures (20/04/2020)
sed -i '414i  } else if (current_cpu == "ppc64") { \n    sources = libvpx_srcs_ppc64'  third_party/libvpx/BUILD.gn
kernel=`uname -r`
sed -i 's/linux\/kcmp.h/\/usr\/src\/kernels\/'$kernel'\/include\/linux\/kcmp.h/g' services/service_manager/sandbox/linux/bpf_cros_amd_gpu_policy_linux.cc
sed -i 's/httpConnect2/httpConnect/g' printing/backend/cups_helper.cc

#Adding power changes to Syscall set files
sed -i -e '/#include <asm\/unistd.h>/a\
#if !defined(__NR_shmdt)\n#define __NR_shmdt 197\n#endif\n\n \
#if !defined(__NR_shmget)\n#define __NR_shmget 194\n#endif\n\n \
#if !defined(__NR_shmctl)\n#define __NR_shmctl 195\n#endif\n\n \
#if !defined(__NR_shmat)\n#define __NR_shmat 196\n#endif\n\n' sandbox/linux/system_headers/ppc64_linux_syscalls.h

perl -i -0pe 's/\(defined\(ARCH_CPU_MIPS_FAMILY\) \&\& defined\(ARCH_CPU_64_BITS\)\)\n\/\/ These give a lot of ambient authority and bypass the setuid sandbox.\nbool SyscallSets::IsSystemVSharedMemory\(int sysno\) {/\(defined\(ARCH_CPU_MIPS_FAMILY\) \&\& defined\(ARCH_CPU_64_BITS\)\) || \\\n defined\(__powerpc64__\)\n\/\/ These give a lot of ambient authority and bypass the setuid sandbox.\nbool SyscallSets::IsSystemVSharedMemory\(int sysno\) {/' sandbox/linux/seccomp-bpf-helpers/syscall_sets.cc

perl -i -0pe 's/\(defined\(ARCH_CPU_MIPS_FAMILY\) \&\& defined\(ARCH_CPU_64_BITS\)\)\n\/\/ These give a lot of ambient authority and bypass the setuid sandbox.\n  static bool IsSystemVSharedMemory\(int sysno\);/\(defined\(ARCH_CPU_MIPS_FAMILY\) \&\& defined\(ARCH_CPU_64_BITS\)\) || \\\n defined\(__powerpc64__\)\n\/\/ These give a lot of ambient authority and bypass the setuid sandbox.\n  static bool IsSystemVSharedMemory\(int sysno\);/' sandbox/linux/seccomp-bpf-helpers/syscall_sets.h


#Generate files
gn gen out/Default

#Build Chromium
ninja-build -C out/Default chrome

# To verify chrome binary
cd out/Default/
./chrome --version
