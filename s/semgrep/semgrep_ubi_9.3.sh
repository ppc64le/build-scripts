#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : semgrep
# Version          : v1.123.0
# Source repo      : https://github.com/semgrep/semgrep.git
# Tested on        : UBI 9.3
# Language         : OCaml, Python
# Travis-Check     : True
# Script License   : GNU Lesser General Public License v2.1
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=semgrep
PACKAGE_VERSION=${1:-v1.123.0}
PACKAGE_URL=https://github.com/semgrep/semgrep
PACKAGE_DIR=semgrep
CURRENT_DIR=$(pwd)


# Installing required dependencies
yum install -y yum-utils vim wget tar curl gzip procps-ng --allowerasing

yum install -y pcre2 pcre2-devel libffi-devel python3 python3-devel python3-pip wget tar git gmp-devel pcre-devel make m4 perl patch unzip which bzip2 diffutils rsync libcurl-devel gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc --allowerasing

export GCC_TOOLSET_PATH=/opt/rh/gcc-toolset-13/root/usr
export PATH=$GCC_TOOLSET_PATH/bin:$PATH


# Install OCaml
wget https://caml.inria.fr/pub/distrib/ocaml-5.2/ocaml-5.2.0.tar.gz
tar -xzf ocaml-5.2.0.tar.gz
cd ocaml-5.2.0
./configure -target ppc64le-linux
make
make install
export PATH=/usr/local/bin:$PATH
ocaml --version
echo "------------------OCaml Build Successful!-------------------------------------"

# Install OPam
cd $CURRENT_DIR
git clone https://github.com/ocaml/opam.git
cd opam
git checkout 2.2.1
./configure --with-vendored-deps
make
make install
opam --version
echo "5" | opam init --disable-sandboxing
eval $(opam env --switch=default)
echo "------------------OPam Build Successful!-------------------------------------"

#Install Dune
opam install dune

#Install libev-devel
cd $CURRENT_DIR
wget https://dist.schmorp.de/libev/Attic/libev-4.33.tar.gz
tar -xzf libev-4.33.tar.gz
cd libev-4.33
./configure --prefix=/usr/local
make
make install
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
mkdir -p /usr/local/lib/pkgconfig
cat <<EOF > /usr/local/lib/pkgconfig/libev.pc
prefix=/usr/local
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: libev
Description: A full-featured and high-performance event loop
Version: 4.33
Libs: -L\${libdir} -lev
Cflags: -I\${includedir}
EOF

export C_INCLUDE_PATH=/usr/local/include:$C_INCLUDE_PATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

#Cloning semgrep repo
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

git submodule update --init --recursive

pip install freezegun python-dateutil pytest-mock appdirs

eval $(opam env)
opam install -y opam-depext
opam depext profiling -y
opam install . --assume-depexts -y || true
make install-deps-for-semgrep-core
make install-deps
make core

#Build package
if ! pip install -e . ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Test package
#Tests are commented out because io_uring fails to allocate memory on Travis CI; uncomment to run locally
#if ! make test ; then
#    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
#    exit 2
#else
#    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
#    echo "$PACKAGE_URL $PACKAGE_NAME"
#    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
#    exit 0
#fi
