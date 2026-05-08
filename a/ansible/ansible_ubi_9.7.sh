#!/bin/bash
# -----------------------------------------------------------------------------
#
# Version           : v2.20.5
# Source repo       : https://github.com/ansible/ansible.git
# Tested on         : UBI:9.7
# Language          : Python
# Ci-Check          : True
# Script License    : Apache License, Version 2 or later
# Maintainer        : Prabhu K(Prabhu.K@ibm.com)
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
# ----------------------------------------------------------------------------
#

PACKAGE_NAME=ansible
PACKAGE_URL=https://github.com/ansible/ansible.git
PACKAGE_VERSION=${1:-v2.20.5}

dnf update -y && dnf upgrade -y

# Installing dependencies

yum install -y git make cmake zip tar wget python3.12 python3.12-devel python3.12-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig rust cargo diffutils libyaml-devel openssh-server openssh-clients

source /opt/rh/gcc-toolset-13/enable

python3.12 -m pip install build pytest pytest-xdist pytest-mock

# ==========================
# Safe SSH setup
# ==========================

# Ensure host keys exist
ssh-keygen -A

# Create .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate ED25519 key
if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
fi

# Add public key to authorized_keys
grep -q -F "$(cat ~/.ssh/id_ed25519.pub)" ~/.ssh/authorized_keys || \
    cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Create SSH config for localhost
cat > ~/.ssh/config <<'EOF'
Host localhost
    User root
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    StrictHostKeyChecking no
EOF
chmod 600 ~/.ssh/config

# Restart sshd safely via systemd
systemctl restart sshd
systemctl enable sshd

# Test SSH locally
ssh -o IdentitiesOnly=yes localhost whoami

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Patching image references to use icr images

sed -i 's|quay.io/ansible/nios-test-container:7.0.0|icr.io/ppc64le-oss/ansible-nios-test-container-ppc64le:7.0.0|g' \
test/lib/ansible_test/_internal/commands/integration/cloud/nios.py

sed -i 's|quay.io/ansible/ansible-test-utility-container:3.4.0|icr.io/ppc64le-oss/ansible-utility-container-ppc64le:3.4.0|g' \
test/lib/ansible_test/_internal/docker_util.py

sed -i 's|quay.io/ansible/http-test-container:3.5.0|icr.io/ppc64le-oss/http-test-container-ppc64le:3.5.0|g' \
test/lib/ansible_test/_internal/commands/integration/cloud/httptester.py


python3.12 -m pip install \
    jinja2 \
    PyYAML \
    packaging \
    resolvelib \
    cryptography
# Ensure system python has runtime deps for SSH testhost
python3.12 -m pip install --upgrade \
    jinja2 \
    PyYAML \
    packaging \
    resolvelib \
    cryptography

#To create virtual environment
python3.12 -m venv /opt/ansible-venv
source /opt/ansible-venv/bin/activate

chmod -R o+rx /opt/ansible-venv

pip install -e .
pip install -r requirements.txt

pip install --upgrade pip

#Installing Package Dependencies
pip install .
pip install build pytest pytest-xdist pytest-mock

#Building Package
if ! python3.12 -m build ; then
    echo "------------------$PACKAGE_NAME:Build_Failure---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Failure"
    exit 1
fi

#Installing requirements for unit testing
pip install -r test/units/requirements.txt

##Unit and Sanity Testing
if ! ./bin/ansible-test units --python 3.12 && ./bin/ansible-test sanity --python 3.12 ; then
    echo "------------------$PACKAGE_NAME:Unit_and_Sanity_Test_Failure---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Test_Failure"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build & Unit_and_Sanity_Test Passed Successfully---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Passed | Build_&_Test_Successfull"

fi

#Integartion-Test
if ! ./bin/ansible-test integration --python 3.12 -vvv  --exclude ansible-test-cloud-galaxy --exclude  ansible-galaxy-collection --exclude ansible-test-coverage --exclude ansible-test-docker --exclude ansible-test-units-assertions --exclude async --exclude connection_ssh --exclude fetch --exclude file --exclude keyword_inheritance --exclude lookup_password --exclude omit --exclude remote_tmp --exclude ansible-test-cloud-cs ; then
    echo "------------------$PACKAGE_NAME:Integration_Test_Failure---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Test_Failure"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build & Integration_Test Passed Successfully---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Passed | Build_&_Test_Successfull"
    exit 0
fi


##Dependency images for integration tests
##quay.io/ansible/cloudstack-test-container        1.7.0
##quay.io/pulp/galaxy                              4.7.1
##quay.io/ansible/acme-test-container              2.1.0

