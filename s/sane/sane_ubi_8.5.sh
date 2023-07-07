#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: sane
# Version	: v4.1.0
# Source repo	: https://github.com/amasad/sane
# Tested on	: ubi 8.5
# Language      : node
# Travis-Check  : false
# Script License: Apache License, Version 2 or later
# Maintainer	: Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME="sane"
PACKAGE_VERSION=${1:-"v4.1.0"}
PACKAGE_URL="https://github.com/amasad/sane"
export NODE_VERSION=${NODE_VERSION:-v14}
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
HOME_DIR="$PWD"

yum install -y git cmake make gcc-c++ python3-devel openssl-devel autoconf automake libtool diffutils ncurses-devel

#installing cargo and rust
curl -o rustup.sh --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs
sh ./rustup.sh -y

#installing nvm  and nodejs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install "$NODE_VERSION"
npm install -g npm@8

#building watchman
git clone https://github.com/facebook/watchman
cd watchman
export WATCHMAN_VERSION=${WATCHMAN_VERSION:-"62122454214a402eff5da78f51911b278524ba0a"}
git checkout "$WATCHMAN_VERSION"

#the following packages have config.guess file in their source
deps=("autoconf" "automake" "libtool" "libicu" "libffi" "python" "lzo" "libsodium" "boost" "nghttp2" "pcre" "libcurl")
for dep in "${deps[@]}"; do
	if python3 build/fbcode_builder/getdeps.py fetch "$dep"; then
		echo "$dep is sucessfully fetched"
	else
		echo "failed to fetch $dep !"
		exit 1
	fi
	# replacing config.guess file in $dep source to avoid build error
	dep_source=$(python3 build/fbcode_builder/getdeps.py show-source-dir "$dep")
	find "$dep_source" -name "config.guess" -exec sh -c 'cp /usr/share/automake*/config.guess $1' _ {} \;
	if python3 build/fbcode_builder/getdeps.py build "$dep" &>/dev/null; then
		echo "$dep is sucessfully build "
	else
		echo "failed to build  $dep !"
		exit 1
	fi
done

#building watchman
./autogen.sh
# uncommment following line  to run the test for watchman
#python3 build/fbcode_builder/getdeps.py test --src-dir=. watchman --project-install-prefix=watch:/usr/local
cp -r ./built/* /usr/local/
mkdir -p  /usr/local/var/run/watchman/root-state: 

cd "$HOME_DIR" 
echo "cloning..."
if ! git clone -q $PACKAGE_URL $PACKAGE_NAME; then
	echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails"
	exit 1
fi

cd "$HOME_DIR"/$PACKAGE_NAME || exit 1
git checkout "$PACKAGE_VERSION" || exit 1

#building and testing sane
if ! npm i; then
	echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
	exit 1
fi

if ! npm test; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
	exit 0
fi
