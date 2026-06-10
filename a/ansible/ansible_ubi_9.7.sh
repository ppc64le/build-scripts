#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package           : ansible
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

# Note: For Integration Tests, containeer needs to start with privileged mode

PACKAGE_NAME=ansible
PACKAGE_URL=https://github.com/ansible/ansible.git
PACKAGE_VERSION=${1:-v2.20.5}

dnf update -y && dnf upgrade -y

# Installing dependencies

yum install -y git make cmake zip tar wget python3.12 python3.12-devel python3.12-pip gcc-toolset-13 gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc zlib-devel libjpeg-devel openssl openssl-devel freetype-devel pkgconfig rust cargo diffutils libyaml-devel openssh-server openssh-clients

source /opt/rh/gcc-toolset-13/enable

python3.12 -m pip install build pytest pytest-xdist pytest-mock

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

## SSH connection to localhost is required for integration testing
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#To create virtual environment
python3.12 -m venv .venv
source .venv/bin/activate

pip install --upgrade pip

# Force install PyYAML to trigger C extension build
pip install --force-reinstall --no-binary=:all: PyYAML

export ANSIBLE_LIBRARY=./test/integration/targets/ansible-doc/library

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

#Unit and Sanity Testing
if ! ./bin/ansible-test units --python 3.12 -vvv && ./bin/ansible-test sanity --python 3.12 -vvv ; then
    echo "------------------$PACKAGE_NAME:Unit_and_Sanity_Test_Failure---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Test_Failure"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build & Unit_and_Sanity_Test Passed Successfully---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Passed | Build_&_Test_Successfull"
fi

# ==========================
# Integration setup/tests
# ==========================

echo "------------------$PACKAGE_NAME:Starting Integration Setup---------------------"

if [ "$EUID" -ne 0 ]; then
    echo "Integration setup requires root because it configures sshd, /etc/hosts, locale, and iptables."
    exit 1
fi

# Extra packages needed by integration tests in minimal UBI/RHEL containers.
dnf install -y \
    openssh-server openssh-clients \
    glibc-langpack-en langpacks-en \
    file acl attr \
    iptables iptables-nft nftables \
    iproute procps-ng util-linux sudo which hostname

dnf install -y glibc-locale-source || true

localedef -i en_US -f UTF-8 en_US.UTF-8 || true

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PYTHONIOENCODING=utf-8

LC_ALL=en_US.UTF-8 locale charmap

# iptables tests need container privileges.
# Run container with:
#   docker run --privileged ...
# or at minimum:
#   --cap-add NET_ADMIN --cap-add NET_RAW
if ! iptables -S >/dev/null 2>&1; then
    echo "iptables is not usable. Run the container with --privileged or NET_ADMIN/NET_RAW."
    exit 1
fi

# Patch helper container image references on ppc64le.
if [ "$(uname -m)" = "ppc64le" ]; then
    sed -i 's|quay.io/ansible/nios-test-container:7.0.0|icr.io/ppc64le-oss/ansible-nios-test-container-ppc64le:7.0.0|g' \
        test/lib/ansible_test/_internal/commands/integration/cloud/nios.py

    sed -i 's|quay.io/ansible/ansible-test-utility-container:3.4.0|icr.io/ppc64le-oss/ansible-utility-container-ppc64le:3.4.0|g' \
        test/lib/ansible_test/_internal/docker_util.py

    sed -i 's|quay.io/ansible/http-test-container:3.5.0|icr.io/ppc64le-oss/http-test-container-ppc64le:3.5.0|g' \
        test/lib/ansible_test/_internal/commands/integration/cloud/httptester.py

    sed -i 's|quay.io/ansible/acme-test-container:2.3.0|icr.io/ppc64le-oss/ansible-acme-test-container-ppc64le:2.3.0|g' \
        test/lib/ansible_test/_internal/commands/integration/cloud/acme.py
fi

# UBI/RHEL 9 containers use the host kernel, so matching kernel-modules-extra
# is usually unavailable. The task is named RHEL 10, so restrict it to RHEL 10+.
python - <<'PY'
from pathlib import Path

p = Path("test/integration/targets/iptables/tasks/main.yml")
text = p.read_text()

old = """- name: install xt_comment for iptables `-m comment` tests on RHEL 10
  dnf:
    name:
    - kernel-modules-extra-{{ ansible_facts.kernel }}
    state: present
    exclude:
    # prevent attempts to upgrade the kernel and install kernel modules for a non-running kernel version
    - kernel-core
  when: ansible_distribution == 'RedHat'
"""

new = """- name: install xt_comment for iptables `-m comment` tests on RHEL 10
  dnf:
    name:
    - kernel-modules-extra-{{ ansible_facts.kernel }}
    state: present
    exclude:
    # prevent attempts to upgrade the kernel and install kernel modules for a non-running kernel version
    - kernel-core
  when:
    - ansible_distribution == 'RedHat'
    - ansible_distribution_major_version | int >= 10
"""

if old in text:
    p.write_text(text.replace(old, new))
else:
    print("iptables patch pattern not found or already patched")
PY

# SSH setup for delegate_to/testhost integration tests.
ssh-keygen -A
mkdir -p /run/sshd ~/.ssh
chmod 700 ~/.ssh

SSH_KEY="$HOME/.ssh/id_ed25519_ansible_test"

if [ ! -f "$SSH_KEY" ]; then
    ssh-keygen -t ed25519 -N "" -f "$SSH_KEY"
fi

grep -q -F "$(cat "$SSH_KEY.pub")" ~/.ssh/authorized_keys 2>/dev/null || \
    cat "$SSH_KEY.pub" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

if ! grep -q "ansible-test loopback hosts begin" /etc/hosts; then
    cat >> /etc/hosts <<'EOF'
# ansible-test loopback hosts begin
127.0.0.1 testhost
127.0.0.2 testhost2
127.0.0.3 testhost3
# ansible-test loopback hosts end
EOF
fi

SSH_CONFIG="$HOME/.ssh/config"
touch "$SSH_CONFIG"
TMP_SSH_CONFIG="$(mktemp)"

awk '
  /# BEGIN ansible-test ssh config/ { skip=1; next }
  /# END ansible-test ssh config/ { skip=0; next }
  skip != 1 { print }
' "$SSH_CONFIG" > "$TMP_SSH_CONFIG"

cat > "$SSH_CONFIG" <<EOF
# BEGIN ansible-test ssh config
Host localhost 127.0.0.* testhost testhost*
    AddressFamily inet
    User root
    Port 22
    IdentityFile $SSH_KEY
    IdentitiesOnly yes
    PreferredAuthentications publickey
    GSSAPIAuthentication no
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
# END ansible-test ssh config

EOF

cat "$TMP_SSH_CONFIG" >> "$SSH_CONFIG"
rm -f "$TMP_SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

port22_listening() {
    ss -ltnH '( sport = :22 )' 2>/dev/null | grep -q .
}

IS_CONTAINER=0
if [ -f /.dockerenv ] || [ -f /run/.containerenv ] || grep -qaE '(docker|podman|containerd|kubepods)' /proc/1/cgroup; then
    IS_CONTAINER=1
fi

SSHD_LOG=/tmp/ansible-test-sshd.log
SSHD_TEST_CONFIG=/tmp/sshd_config_ansible_test

if [ "$IS_CONTAINER" = "0" ] && command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    systemctl enable sshd
    systemctl restart sshd
elif port22_listening; then
    echo "Port 22 already listening; reusing existing sshd."
else
    cat > "$SSHD_TEST_CONFIG" <<'EOF'
Port 22
ListenAddress 0.0.0.0
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
PermitRootLogin yes
AllowUsers root
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
GSSAPIAuthentication no
UsePAM no
StrictModes no
PidFile /tmp/ansible-test-sshd.pid
LogLevel VERBOSE
Subsystem sftp internal-sftp
EOF

    /usr/sbin/sshd -t -f "$SSHD_TEST_CONFIG"
    /usr/sbin/sshd -D -e -f "$SSHD_TEST_CONFIG" > "$SSHD_LOG" 2>&1 &
    SSHD_PID=$!

    trap 'kill "$SSHD_PID" >/dev/null 2>&1 || true' EXIT
fi

for host in localhost 127.0.0.2 127.0.0.3 testhost testhost2 testhost3; do
    for i in {1..20}; do
        if ssh -o BatchMode=yes -o ConnectTimeout=2 "$host" whoami; then
            break
        fi

        if [ "$i" = 20 ]; then
            echo "SSH failed for $host"
            [ -f "$SSHD_LOG" ] && cat "$SSHD_LOG"
            exit 1
        fi

        sleep 1
    done
done

if ! ./bin/ansible-test integration --python 3.12 -vvv \
    --exclude ansible-test-cloud-galaxy \
    --exclude ansible-galaxy-collection \
    --exclude ansible-test-coverage \
    --exclude ansible-test-docker \
    --exclude ansible-test-units-assertions \
    --exclude async \
    --exclude connection_ssh \
    --exclude fetch \
    --exclude file \
    --exclude keyword_inheritance \
    --exclude lookup_password \
    --exclude omit \
    --exclude remote_tmp \
    --exclude ansible-test-cloud-cs \
    --exclude module_no_log \
    --exclude service_facts ; then
    echo "------------------$PACKAGE_NAME:Integration_Test_Failure---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Test_Failure"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Build & Unit/Sanity & Integration Tests Passed Successfully---------------------"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Passed | Build_&_Test_Successfull"
    exit 0
fi

##Other dependency images for integration tests
##quay.io/ansible/cloudstack-test-container        1.7.0
##quay.io/pulp/galaxy                              4.7.1
##quay.io/ansible/acme-test-container              2.1.0

