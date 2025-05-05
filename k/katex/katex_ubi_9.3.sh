#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : KaTeX
# Version       : v0.16.11
# Source repo   : https://github.com/KaTeX/KaTeX
# Tested on     : UBI:9.3
# Language      : JavaScript
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : stutiibm <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------


PACKAGE_VERSION=${1:-v0.16.11}
PACKAGE_URL=https://github.com/KaTeX/KaTeX
PACKAGE_NAME=KaTeX
export NODE_VERSION=${NODE_VERSION:-20}
HOME_DIR=${PWD}

#installing dependencies
yum install -y yum-utils git wget tar gzip python3 python3-devel gcc gcc-c++ make cmake diffutils g++  m4 unzip patch bzip2


#Installing Nodejs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION
node -v

#installing opam
wget https://github.com/ocaml/opam/releases/download/2.3.0/opam-2.3.0-ppc64le-linux
chmod +x opam-2.3.0-ppc64le-linux
mv opam-2.3.0-ppc64le-linux /usr/local/bin/opam
opam --version
yes 1 | opam init --disable-sandboxing
opam switch create 4.07.1
eval $(opam env)
opam install ocamlbuild ocamlfind base ocamlfind ppx_deriving sedlex wtf8 dtoa ocaml-migrate-parsetree.1.8.0 visitors lwt lwt_ppx ppx_let lwt_log ppx_gen_rec --yes

ocamlc -version
ocamlbuild --version
which ocamlfind

#installing flow
git clone https://github.com/facebook/flow.git
cd flow
git checkout v0.135.0
make CC_FLAGS=""
ls $HOME_DIR/flow/bin/flow
export PATH=$PATH:$HOME_DIR/flow/bin
flow --version
cd ..



#Cloning repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

corepack enable

if ! (yes y | yarn install); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

yes y |npx update-browserslist-db@latest

mkdir $HOME_DIR/KaTeX/.yarn/unplugged/flow-bin-npm-0.135.0-653649e23c/node_modules/flow-bin/flow-linuxppc64-v0.135.0
cp $HOME_DIR/flow/bin/flow $HOME_DIR/KaTeX/.yarn/unplugged/flow-bin-npm-0.135.0-653649e23c/node_modules/flow-bin/flow-linuxppc64-v0.135.0/flow

FILE_PATH="${HOME_DIR}/KaTeX/.yarn/unplugged/flow-bin-npm-0.135.0-653649e23c/node_modules/flow-bin/cli.js"
sed -i "s|var bin = require('./');|var bin = __dirname + '/flow-linuxppc64-v0.135.0/flow';|" "$FILE_PATH"


if ! yarn test; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi


