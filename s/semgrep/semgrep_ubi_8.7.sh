#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : semgrep
# Version          : v1.48.0
# Source repo      : https://github.com/semgrep/semgrep.git
# Tested on        : UBI 8.7
# Language         : OCaml, Python
# Ci-Check     : True
# Script License   : GNU Lesser General Public License v2.1
# Maintainer       : Pooja Shah <Pooja.Shah4@ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=semgrep
PACKAGE_VERSION=${1:-v1.48.0}
PACKAGE_URL=https://github.com/semgrep/semgrep.git
HOME_DIR=$PWD

# Adding repos to install required dependencies
sudo yum install -y yum-utils vim wget tar curl gzip procps-ng
sudo yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/
sudo yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/
sudo yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/
wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
sudo mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/.
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official
sudo yum install -y curl libffi-devel python39 python39-devel python39-pip gcc gcc-c++ wget tar git gmp-devel pcre-devel make m4 perl patch unzip bubblewrap which bzip2 diffutils rsync
sudo dnf install -y mercurial

# Install OCaml
cd $HOME_DIR
wget https://caml.inria.fr/pub/distrib/ocaml-4.14/ocaml-4.14.1.tar.gz 
tar -xzf ocaml-4.14.1.tar.gz 
cd ocaml-4.14.1
./configure -target ppc64le-linux
make world.opt
sudo make install
export PATH=/usr/local/bin:$PATH
ocaml --version

# Install OPam
cd $HOME_DIR
git clone https://github.com/ocaml/opam.git && cd opam
./configure --with-vendored-deps
make
sudo make install
opam --version
echo "5" | opam init --disable-sandboxing
eval $(opam env --switch=default)

# Build, Install and Test Semgrep
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

make setup
python3 -m pip install pipenv pre-commit
sed -i 's/jsonnet/jsonnet-binary/g' $HOME_DIR/semgrep/cli/Pipfile.lock 
sed -i 's/7e770c7bf3a366b97b650a39430450f77612e74406731eb75c5bd59f3f104d4f/fbadf25f28161b0ccf29e0b72ef689790d14a9b23a681ab6846bd7cb12e17f1d/g' $HOME_DIR/semgrep/cli/Pipfile.lock 
sed -i 's/0.20.0/0.17.0/g' $HOME_DIR/semgrep/cli/Pipfile.lock

if ! make build; then
        echo "Build Fails!"
        exit 1
elif ! sudo make install; then
        echo "Install Fails!"
        exit 1
elif ! make check; then
        echo "Test Fails!"
        exit 2
else
        export PATH=/usr/local/bin:$PATH
        semgrep --version | grep ${PACKAGE_VERSION:1}
        echo "Build, Install and Test Success!!"
        exit 0
fi