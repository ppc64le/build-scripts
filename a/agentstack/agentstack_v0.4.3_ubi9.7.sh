#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : agentstack
# Version       : v0.4.3
# Source repo   : https://github.com/i-am-bee/agentstack.git
# Tested on     : UBI 9.7
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Simran Sirsat<Simran.Sirsat@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -euo pipefail

###############################################################################
# CONFIG
###############################################################################

PACKAGE_NAME=agentstack
PACKAGE_URL=https://github.com/i-am-bee/agentstack.git

SCRIPT_PACKAGE_VERSION="v0.4.3"
PACKAGE_VERSION="${1:-${SCRIPT_PACKAGE_VERSION}}"

PGVECTOR_VERSION="${PGVECTOR_VERSION:-v0.7.4}"
POSTGRES_VERSION="${POSTGRES_VERSION:-16.4}"

BUILD_HOME=$(pwd)

POSTGRES_INSTALL_DIR="${POSTGRES_INSTALL_DIR:-/local/apps/postgresql/pgsql164}"
POSTGRES_DATA_DIR="${POSTGRES_DATA_DIR:-${POSTGRES_INSTALL_DIR}/data}"

POSTGRES_SOURCE_URL="https://ftp.postgresql.org/pub/source/v${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.tar.gz"
POSTGRES_SOURCE_TAR="postgresql-${POSTGRES_VERSION}.tar.gz"
POSTGRES_SRC_DIR="postgresql-${POSTGRES_VERSION}"

PGVECTOR_REPO_URL="https://github.com/pgvector/pgvector.git"

RUN_KIND_SETUP="${RUN_KIND_SETUP:-true}"
RUN_UNIT_TESTS="${RUN_UNIT_TESTS:-true}"
RUN_INTEGRATION_TESTS="${RUN_INTEGRATION_TESTS:-true}"

KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-mkpod}"
KIND_IMAGE="${KIND_IMAGE:-quay.io/powercloud/kind-node}"
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.36.0}"

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github


###############################################################################
# SYSTEM DEPENDENCIES
###############################################################################

echo "=============================================================================="
echo "Installing system dependencies"
echo "=============================================================================="

ret=0

if [ $ret -ne 0 ]; then
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os

    rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256
fi

dnf install -y \
    wget \
    git \
    curl-devel \
    gcc \
    gcc-c++ \
    make \
    cmake \
    patch \
    llvm-devel \
    clang \
    clang-devel \
    readline \
    readline-devel \
    openssl-devel \
    pkgconfig \
    ca-certificates \
    dnf-plugins-core \
    libpq-devel \
    zlib-devel \
    libicu-devel \
    libjpeg-turbo-devel \
    libjpeg-turbo \
    postgresql \
    postgresql-devel \
    freetype-devel \
    freetype \
    libpng-devel 

###############################################################################
# DOCKER
###############################################################################

echo "=============================================================================="
echo "Installing Docker"
echo "=============================================================================="

dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || true
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

docker --version

###############################################################################
# RUST
###############################################################################

echo "=============================================================================="
echo "Installing Rust"
echo "=============================================================================="

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

rustc --version
cargo --version

###############################################################################
# PYTHON / UV
###############################################################################

echo "=============================================================================="
echo "Installing uv"
echo "=============================================================================="

curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

uv --version

###############################################################################
# GO
###############################################################################

echo "=============================================================================="
echo "Installing Go"
echo "=============================================================================="

GO_VERSION="1.24.4"
GO_TAR="go${GO_VERSION}.linux-ppc64le.tar.gz"

cd "$BUILD_HOME"
wget "https://go.dev/dl/${GO_TAR}"
rm -rf /usr/local/go
tar -C /usr/local -xzf "${GO_TAR}"
rm -f "${GO_TAR}"

export GOROOT="/usr/local/go"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

go version

###############################################################################
# BUILD POSTGRESQL FROM SOURCE
###############################################################################

echo "=============================================================================="
echo "Building PostgreSQL ${POSTGRES_VERSION}"
echo "=============================================================================="

cd "$BUILD_HOME"

if [ ! -f "${POSTGRES_SOURCE_TAR}" ]; then
    wget "${POSTGRES_SOURCE_URL}"
fi

rm -rf "${POSTGRES_SRC_DIR}"
tar xf "${POSTGRES_SOURCE_TAR}"
cd "${POSTGRES_SRC_DIR}"

./configure --without-readline --prefix="${POSTGRES_INSTALL_DIR}" --with-pgport=5433
make -j"$(nproc)"
make install

###############################################################################
# SETUP POSTGRES USER / DATA / SERVER
###############################################################################

echo "=============================================================================="
echo "Setting up PostgreSQL"
echo "=============================================================================="

id postgres >/dev/null 2>&1 || useradd -d /home/postgres/ postgres
echo "postgres:lormipsum" | chpasswd || true

mkdir -p "${POSTGRES_DATA_DIR}"
chown -R postgres:postgres "${POSTGRES_INSTALL_DIR}"

if [ ! -f "${POSTGRES_DATA_DIR}/PG_VERSION" ]; then
    su - postgres -c "${POSTGRES_INSTALL_DIR}/bin/initdb -D ${POSTGRES_DATA_DIR}"
fi

su - postgres -c "${POSTGRES_INSTALL_DIR}/bin/pg_ctl -D ${POSTGRES_DATA_DIR} -l /home/postgres/logfile start" || true

until su - postgres -c "${POSTGRES_INSTALL_DIR}/bin/pg_isready -h localhost -p 5433" >/dev/null 2>&1; do
    sleep 2
done

su - postgres -c "${POSTGRES_INSTALL_DIR}/bin/psql -v ON_ERROR_STOP=1 postgres <<'SQL'
DO
\$do\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'agentstack-user') THEN
      CREATE ROLE \"agentstack-user\" LOGIN PASSWORD 'agentstack';
   END IF;
END
\$do\$;
SQL"

su - postgres -c "${POSTGRES_INSTALL_DIR}/bin/psql -tAc \"SELECT 1 FROM pg_database WHERE datname='agentstack'\"" | grep -q 1 \
    || su - postgres -c "${POSTGRES_INSTALL_DIR}/bin/createdb -O agentstack-user agentstack"

###############################################################################
# BUILD PGVECTOR
###############################################################################

echo "=============================================================================="
echo "Building pgvector ${PGVECTOR_VERSION}"
echo "=============================================================================="

cd "$BUILD_HOME"
rm -rf pgvector
git clone "${PGVECTOR_REPO_URL}"
cd pgvector
git checkout "${PGVECTOR_VERSION}"

sed -i "s|pg_config|${POSTGRES_INSTALL_DIR}/bin/pg_config|g" Makefile

make -j"$(nproc)"
make install

export PGVECTOR_Build="${POSTGRES_INSTALL_DIR}/lib/vector.so"

echo "PostgreSQL and pgvector installation completed."
echo "pgvector binary is available at [${PGVECTOR_Build}]."

###############################################################################
# ENABLE PGVECTOR EXTENSION
###############################################################################

echo "=============================================================================="
echo "Enabling pgvector extension"
echo "=============================================================================="

su - postgres -c "${POSTGRES_INSTALL_DIR}/bin/psql -d agentstack -c 'CREATE EXTENSION IF NOT EXISTS vector;'"

echo "=============================================================================="
echo "Resetting PostgreSQL credentials"
echo "=============================================================================="

su - postgres -c "${POSTGRES_INSTALL_DIR}/bin/psql postgres <<'SQL'
ALTER ROLE "agentstack-user"
WITH LOGIN PASSWORD 'agentstack';
SQL
"

echo "=============================================================================="
echo "Verifying PostgreSQL login"
echo "=============================================================================="

PGPASSWORD=agentstack \
${POSTGRES_INSTALL_DIR}/bin/psql \
-h localhost \
-p 5433 \
-U agentstack-user \
-d agentstack \
-c "select version();"


###############################################################################
# CLONE AGENTSTACK
###############################################################################

echo "=============================================================================="
echo "Cloning AgentStack"
echo "=============================================================================="

cd "${BUILD_HOME}"
git clone "${PACKAGE_URL}"
cd $PACKAGE_NAME
git checkout "${PACKAGE_VERSION}"
AGENTSTACK_ROOT="${BUILD_HOME}/agentstack"

wget https://raw.githubusercontent.com/Simran-Sirsat/build-scripts/agentstack/a/agentstack/agentstack_v0.4.3.patch
#wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/a/agentstack/agentstack_v0.4.3.patch

git apply agentstack_v0.4.3.patch

export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1

###############################################################################
# BUILD AGENTSTACK SDK (PYTHON)
###############################################################################

echo "=============================================================================="
echo "Setting up AgentStack SDK Python"
echo "=============================================================================="

cd "${AGENTSTACK_ROOT}/apps/agentstack-sdk-py"

uv python install 3.12
deactivate 2>/dev/null || true
unset VIRTUAL_ENV
hash -r

rm -rf .venv
uv venv .venv --python 3.12
source .venv/bin/activate
rm -f uv.lock

if ! (
    uv lock &&
    uv sync
); then
    echo "------------------${PACKAGE_NAME}:agentstack_sdk_build_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | ${SOURCE} | Fail | AgentStack_SDK_Build_Fails"
    exit 1
fi

###############################################################################
# BUILD AGENTSTACK CLI
###############################################################################

echo "=============================================================================="
echo "Setting up AgentStack CLI"
echo "=============================================================================="

cd "${AGENTSTACK_ROOT}/apps/agentstack-cli"

if ! (
    rm -f uv.lock &&
    uv lock &&
    uv sync
); then
    echo "------------------${PACKAGE_NAME}:agentstack_cli_build_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | ${SOURCE} | Fail | AgentStack_CLI_Build_Fails"
    exit 1
fi

###############################################################################
# BUILD AGENTSTACK SERVER
###############################################################################

echo "=============================================================================="
echo "Setting up AgentStack Server"
echo "=============================================================================="

cd "${AGENTSTACK_ROOT}/apps/agentstack-server"

if ! (
    rm -f uv.lock &&
    uv lock &&
    uv sync &&
    uv add "pydantic==2.11.7" &&
    uv sync
); then
    echo "------------------${PACKAGE_NAME}:agentstack_server_build_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | ${SOURCE} | Fail | AgentStack_Server_Build_Fails"
    exit 1
fi

###############################################################################
# BUILD CHAT AGENT
###############################################################################

echo "=============================================================================="
echo "Setting up chat agent"
echo "=============================================================================="

cd "${AGENTSTACK_ROOT}/agents/chat"

if ! (
    rm -f uv.lock &&
    uv lock &&
    uv sync
); then
    echo "------------------${PACKAGE_NAME}:chat_agent_build_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | ${SOURCE} | Fail | Chat_Agent_Build_Fails"
    exit 1
fi

###############################################################################
# BUILD FORM AGENT
###############################################################################

echo "=============================================================================="
echo "Setting up form agent"
echo "=============================================================================="

cd "${AGENTSTACK_ROOT}/agents/form"

if ! (
    rm -f uv.lock &&
    uv lock &&
    uv sync
); then
    echo "------------------${PACKAGE_NAME}:form_agent_build_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | ${SOURCE} | Fail | Form_Agent_Build_Fails"
    exit 1
fi

###############################################################################
# BUILD RAG AGENT
###############################################################################

echo "=============================================================================="
echo "Setting up rag agent"
echo "=============================================================================="

cd "${AGENTSTACK_ROOT}/agents/rag"

if ! (
    rm -f uv.lock &&
    uv lock &&
    uv sync
); then
    echo "------------------${PACKAGE_NAME}:rag_agent_build_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | ${SOURCE} | Fail | Rag_Agent_Build_Fails"
    exit 1
fi


###############################################################################
# SERVER ENVIRONMENT
###############################################################################

echo "=============================================================================="
echo "Configuring AgentStack Server environment"
echo "=============================================================================="

SERVER_DIR="${AGENTSTACK_ROOT}/apps/agentstack-server"
cd "${SERVER_DIR}"

if [ -f template.env ]; then
    cp template.env .env
elif [ ! -f .env ]; then
    touch .env
fi

sed -i '/^AUTH__DISABLE_AUTH=/d' .env || true
sed -i '/^OIDC__DISABLE_OIDC=/d' .env || true
sed -i '/^PERSISTENCE__DB_URL=/d' .env || true

cat >> .env <<EOF

AUTH__DISABLE_AUTH=true
OIDC__DISABLE_OIDC=true
PERSISTENCE__DB_URL=postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack
EOF


###############################################################################
# DATABASE MIGRATIONS
###############################################################################
export PERSISTENCE__DB_URL="postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack"
export DATABASE_URL="$PERSISTENCE__DB_URL"
export DB_URL="postgresql+asyncpg://agentstack-user:agentstack@localhost:5433/agentstack"

python3 - <<'EOF'
import os
print("DATABASE_URL =", os.getenv("DATABASE_URL"))
print("PERSISTENCE__DB_URL =", os.getenv("PERSISTENCE__DB_URL"))
EOF

echo "=============================================================================="
echo "Running migrations"
echo "=============================================================================="

cd "${SERVER_DIR}"
uv run migrate

###############################################################################
# KIND SETUP
###############################################################################

if [ "${RUN_KIND_SETUP}" = "true" ]; then
    echo "=============================================================================="
    echo "Setting up KinD cluster"
    echo "=============================================================================="

    cd "${BUILD_HOME}"

    rm -rf kind
    git clone https://github.com/kubernetes-sigs/kind.git
    cd kind
    make build
    cp "${BUILD_HOME}/kind/bin/kind" /usr/local/bin/kind
    chmod +x /usr/local/bin/kind

    cd "${BUILD_HOME}"
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/ppc64le/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    kubectl version --client

    VSI_IP=$(ip -4 route show default | awk '{print $3}')

KIND_IMAGE='quay.io/powercloud/kind-node'
KIND_CLUSTER_NAME='mkpod'

cat <<YAML > /root/kind-config.yaml
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: ${KIND_CLUSTER_NAME}
networking:
  apiServerAddress: "${VSI_IP}"
  apiServerPort: 6443
nodes:
- extraMounts:
  - containerPath: /var/lib/kubelet/config.json
    hostPath: /root/config.json
  image: ${KIND_IMAGE}:${KUBECTL_VERSION}
  role: control-plane
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      certSANs:
      - "127.0.0.1"
      - "${VSI_IP}"
      - "localhost"
- extraMounts:
  - containerPath: /var/lib/kubelet/config.json
    hostPath: /root/config.json
  image: ${KIND_IMAGE}:${KUBECTL_VERSION}
  role: worker
YAML


    kind delete cluster --name "${KIND_CLUSTER_NAME}" || true
    kind create cluster --config=/root/kind-config.yaml

###############################################################################
# Export kubeconfig
###############################################################################

mkdir -p "$HOME/.agentstack/docker/agentstack-local-test/copied-from-guest"
export KUBECONFIG="$HOME/.agentstack/docker/agentstack-local-test/copied-from-guest/kubeconfig.yaml"

kind get kubeconfig --name "${KIND_CLUSTER_NAME}" > "$KUBECONFIG"
kubectl config use-context "kind-${KIND_CLUSTER_NAME}"

echo "Using kubeconfig:"
echo "$KUBECONFIG"

kubectl config current-context

###############################################################################
# Wait for cluster
###############################################################################

echo "Waiting for Kubernetes API..."

for i in $(seq 1 60); do
    if kubectl cluster-info >/dev/null 2>&1; then
        break
    fi
    sleep 5
done

echo "Waiting for nodes..."

kubectl wait \
    --for=condition=Ready \
    node \
    --all \
    --timeout=300s

kubectl cluster-info
kubectl get nodes

fi


###############################################################################
# UNIT TESTS
###############################################################################

echo "=============================================================================="
echo "Running Unit Tests"
echo "=============================================================================="

cd "${SERVER_DIR}"

if [ "${RUN_UNIT_TESTS}" = "true" ]; then
    if ! uv run pytest tests/unit -v; then
        echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
        echo "${PACKAGE_URL} ${PACKAGE_NAME}"
        echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | ${SOURCE} | Fail | Unit_Test_Fails"
        exit 2
    fi
fi

###############################################################################
# INTEGRATION TESTS
###############################################################################

echo "=============================================================================="
echo "Checking database connectivity before tests"
echo "=============================================================================="

PGPASSWORD=agentstack \
${POSTGRES_INSTALL_DIR}/bin/psql \
-h localhost \
-p 5433 \
-U agentstack-user \
-d agentstack \
-c "select current_database(), current_user;"

uv run python - <<'EOF'
import asyncio
import asyncpg

async def main():
    conn = await asyncpg.connect(
        host="localhost",
        port=5433,
        user="agentstack-user",
        password="agentstack",
        database="agentstack",
    )
    print(await conn.fetchval("select version()"))
    await conn.close()

asyncio.run(main())
EOF

###############################################################################
# INTEGRATION TESTS
###############################################################################

echo "=============================================================================="
echo "Running Integration Tests"
echo "=============================================================================="

if [ "${RUN_INTEGRATION_TESTS}" = "true" ]; then
    if ! uv run pytest tests/integration -v -m integration; then
        echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
        echo "${PACKAGE_URL} ${PACKAGE_NAME}"
        echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | ${OS_NAME} | ${SOURCE} | Fail | Integration_Test_Fails"
        exit 2
    fi
fi

###############################################################################
# SUMMARY
###############################################################################

echo "=============================================================================="
echo "AgentStack build/setup completed successfully"
echo "AgentStack version : ${PACKAGE_VERSION}"
echo "PostgreSQL version : ${POSTGRES_VERSION}"
echo "pgvector version   : ${PGVECTOR_VERSION}"
echo "KinD setup         : ${RUN_KIND_SETUP}"
echo "Unit tests         : ${RUN_UNIT_TESTS}"
echo "Integration tests  : ${RUN_INTEGRATION_TESTS}"
echo "=============================================================================="