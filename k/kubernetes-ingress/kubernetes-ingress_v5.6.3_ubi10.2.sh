#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : kubernetes-ingress
# Version       : v5.6.3
# Source repo   : https://github.com/nginx/kubernetes-ingress
# Tested on     : UBI 10.2
# Language      : Go
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=kubernetes-ingress
SCRIPT_PACKAGE_VERSION=v5.6.3
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/nginx/kubernetes-ingress
PACKAGE_DIR=kubernetes-ingress

BUILD_HOME=$(pwd)
SCRIPT_PATH=$(dirname "$(realpath "$0")")
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

GO_VERSION=${GO_VERSION:-1.27.3}
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.34.0}"
HELM_VERSION="${HELM_VERSION:-v3.18.6}"
KIND_IMAGE="${KIND_IMAGE:-quay.io/powercloud/kind-node:v1.34.0}"
KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-mkpod}"
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"

# ---------------------------------------------------------------------------
# System packages
# ---------------------------------------------------------------------------
dnf install -y --allowerasing \
    git curl make gcc gcc-c++ openssl tar patch diffutils file findutils procps-ng which \
    python3 python3-pip

PYTHON3=python3
${PYTHON3} --version
${PYTHON3} -m pip install --upgrade pip

# ---------------------------------------------------------------------------
# Go
# ---------------------------------------------------------------------------
if [ ! -x /usr/local/go/bin/go ] || \
   ! /usr/local/go/bin/go version 2>/dev/null | grep -q "go${GO_VERSION}"; then
    curl -fsSL "https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz" \
        -o /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm -f /tmp/go.tar.gz
fi

export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=/usr/local/go/bin:$GOPATH/bin:/usr/local/bin:$PATH
export GO111MODULE=on
go version

# ---------------------------------------------------------------------------
# Clone & checkout
# ---------------------------------------------------------------------------
cd "${BUILD_HOME}"
rm -rf "${PACKAGE_DIR}"
if ! git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Clone_Fails"
    exit 1
fi
cd "${PACKAGE_DIR}"
git checkout "${PACKAGE_VERSION}"
REPO_ROOT=$(pwd)
IC_VERSION="${PACKAGE_VERSION#v}"

# ---------------------------------------------------------------------------
# Build nginx-ingress binary
# -X main.version required by test_build_info.py
# ---------------------------------------------------------------------------
if ! CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le go build -trimpath \
        -ldflags "-s -w -X main.version=${IC_VERSION} -X main.telemetryEndpoint=oss.edge.df.f5.com:443" \
        -o nginx-ingress \
        github.com/nginx/kubernetes-ingress/cmd/nginx-ingress; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi

# ---------------------------------------------------------------------------
# Generate embed certs required by internal/k8s/secrets tests
# (embeds-ca.crt / embeds-ca.key are go:embed files; make cover fails without them)
# ---------------------------------------------------------------------------
cd "${REPO_ROOT}/hack/secrets-gen"
make run
cd "${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Unit tests 
# ---------------------------------------------------------------------------
if ! make cover; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
fi


PATCH_FILE="/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch"
if [ ! -f "${PATCH_FILE}" ]; then
    PATCH_FILE="${SCRIPT_PATH}/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch"
fi
if [ ! -f "${PATCH_FILE}" ]; then
    echo "ERROR: patch file not found at ${PATCH_FILE}"
    exit 1
fi
echo "Applying patch from ${PATCH_FILE}..."
if ! patch -p1 --forward < "${PATCH_FILE}"; then
    echo "------------------$PACKAGE_NAME:patch_fails---------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Patch_Fails"
    exit 1
fi

# ---------------------------------------------------------------------------
# E2E tests (Kind + host docker daemon) run only with RUN_E2E=true
# ---------------------------------------------------------------------------
if [ "${RUN_E2E:-false}" != "true" ]; then
    echo "RUN_E2E is not 'true' - skipping docker/Kind based e2e tests."
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi

# ---------------------------------------------------------------------------
# Docker (e2e only)
# ---------------------------------------------------------------------------
CONTAINER_NAME=$(cat /etc/hostname 2>/dev/null || hostname 2>/dev/null)
if ! command -v docker &>/dev/null; then
    echo "ERROR: docker CLI not found."
    echo "       docker cp \$(which docker) ${CONTAINER_NAME}:/usr/local/bin/docker"
    exit 1
fi
export DOCKER_HOST=unix:///host-docker.sock
docker version
docker info

DOCKER_GATEWAY=$(docker network inspect bridge \
    --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null || echo "172.17.0.1")
echo "Docker bridge gateway: ${DOCKER_GATEWAY}"

# ---------------------------------------------------------------------------
# kubectl (e2e only)
# ---------------------------------------------------------------------------
if ! command -v kubectl &>/dev/null; then
    curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/ppc64le/kubectl" \
        -o /usr/local/bin/kubectl
    chmod +x /usr/local/bin/kubectl
fi
kubectl version --client

# ---------------------------------------------------------------------------
# Helm (e2e only)
# ---------------------------------------------------------------------------
if ! command -v helm &>/dev/null; then
    curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-ppc64le.tar.gz" \
        -o /tmp/helm.tar.gz
    tar -zxf /tmp/helm.tar.gz -C /tmp
    mv /tmp/linux-ppc64le/helm /usr/local/bin/helm
    chmod +x /usr/local/bin/helm
    rm -f /tmp/helm.tar.gz
fi
helm version

# ---------------------------------------------------------------------------
# Kind (e2e only)
# ---------------------------------------------------------------------------
if ! command -v kind &>/dev/null; then
    cd "${BUILD_HOME}"
    rm -rf kind-src
    git clone https://github.com/kubernetes-sigs/kind.git kind-src
    cd kind-src
    make build
    cp bin/kind /usr/local/bin/kind
    chmod +x /usr/local/bin/kind
    cd "${BUILD_HOME}"
fi
kind version
cd "${REPO_ROOT}"

# ---------------------------------------------------------------------------
# Chart.yaml appVersion — test_build_info.py asserts chart version == IC version
# ---------------------------------------------------------------------------
IC_VERSION_CLEAN="${IC_VERSION}"
grep -q "^appVersion: ${IC_VERSION_CLEAN}$" "${REPO_ROOT}/charts/nginx-ingress/Chart.yaml" || \
    sed -i "s/^appVersion:.*/appVersion: ${IC_VERSION_CLEAN}/" \
        "${REPO_ROOT}/charts/nginx-ingress/Chart.yaml"

# ---------------------------------------------------------------------------
# IC Image
# ---------------------------------------------------------------------------
NGINX_IC_IMAGE="nginx/nginx-ingress-ppc64le:${IC_VERSION}-ubi"
echo "Using pre-built IC image: ${NGINX_IC_IMAGE}"
if ! docker image inspect "${NGINX_IC_IMAGE}" &>/dev/null; then
    echo "ERROR: ${NGINX_IC_IMAGE} not found on the VM host docker daemon."
    exit 1
fi
# Record exactly which image is under test (the tag can be moved on the host).
docker image inspect "${NGINX_IC_IMAGE}" --format 'IC image under test: id={{.Id}} created={{.Created}}'

# ---------------------------------------------------------------------------
# KIND CLUSTER
# ---------------------------------------------------------------------------
BACKEND_IMAGE="nginxdemos/nginx-hello:plain-text"
NGINX_ALPINE_IMAGE="nginx:alpine"
NGINX_PLAIN_IMAGE="nginx"
docker pull "${BACKEND_IMAGE}"      || true
docker pull "${NGINX_ALPINE_IMAGE}" || true
docker pull "${NGINX_PLAIN_IMAGE}"  || true
# Upstream e2e test-app images (multi-arch, include ppc64le) that are loaded into Kind below
for _img in tcp udp grpc; do
    docker pull "ghcr.io/nginx/kic-test-${_img}-server:0.2.6" || true
done
# cert-manager v1.21.2 (ppc64le images exist) for the vs_certmanager batch; the version must
# match the images referenced in tests/data/virtual-server-certmanager/certmanager.yaml
CERTMANAGER_IMAGES=(
    quay.io/jetstack/cert-manager-cainjector:v1.21.2
    quay.io/jetstack/cert-manager-controller:v1.21.2
    quay.io/jetstack/cert-manager-webhook:v1.21.2
)
for _img in "${CERTMANAGER_IMAGES[@]}"; do
    docker pull "${_img}" || true
done

# external-dns for the vs_externaldns batch.
EXTERNALDNS_IMAGE=$(grep -o 'registry.k8s.io/external-dns/external-dns:v[0-9][0-9.]*' \
    "${REPO_ROOT}/tests/data/virtual-server-external-dns/external-dns.yaml" | head -1)
if [ -z "${EXTERNALDNS_IMAGE}" ]; then
    echo "ERROR: could not find the external-dns image in tests/data/virtual-server-external-dns/external-dns.yaml"
    exit 1
fi
EXTERNALDNS_TAG="${EXTERNALDNS_IMAGE##*:}"
EXTERNALDNS_BUILD_DIR=$(mktemp -d)
echo "Building ${EXTERNALDNS_IMAGE} for ppc64le from source (${EXTERNALDNS_TAG})..."
if ! ( git clone --depth 1 --branch "${EXTERNALDNS_TAG}" \
            https://github.com/kubernetes-sigs/external-dns.git "${EXTERNALDNS_BUILD_DIR}/src" \
        && cd "${EXTERNALDNS_BUILD_DIR}/src" \
        && CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le go build -trimpath -ldflags "-s -w" \
            -o "${EXTERNALDNS_BUILD_DIR}/external-dns" . \
        && cd "${EXTERNALDNS_BUILD_DIR}" \
        && printf 'FROM scratch\nCOPY external-dns /external-dns\nUSER 65534:65534\nENTRYPOINT ["/external-dns"]\n' > Dockerfile \
        && docker build -q -t "${EXTERNALDNS_IMAGE}" . ); then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi
rm -rf "${EXTERNALDNS_BUILD_DIR}"
docker image inspect "${EXTERNALDNS_IMAGE}" --format 'external-dns image: id={{.Id}} arch={{.Architecture}}'

kind delete cluster --name "${KIND_CLUSTER_NAME}" 2>/dev/null || true

echo 1024   > /proc/sys/fs/inotify/max_user_instances 2>/dev/null || true
echo 524288 > /proc/sys/fs/inotify/max_user_watches   2>/dev/null || true

modprobe nf_conntrack 2>/dev/null || true
modprobe ip_vs        2>/dev/null || true
modprobe ip_vs_rr     2>/dev/null || true
modprobe ip_vs_wrr    2>/dev/null || true
modprobe ip_vs_sh     2>/dev/null || true

cat > /tmp/kind-config.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  apiServerAddress: "0.0.0.0"
nodes:
- role: control-plane
  image: ${KIND_IMAGE}
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".containerd]
    snapshotter = "native"
kubeadmConfigPatches:
- |
  kind: KubeProxyConfiguration
  apiVersion: kubeproxy.config.k8s.io/v1alpha1
  mode: "ipvs"
  ipvs:
    scheduler: "rr"
EOF

kind create cluster \
    --name "${KIND_CLUSTER_NAME}" \
    --config /tmp/kind-config.yaml \
    --wait 300s || true

# Connect this container to the Kind docker network so Kind node IPs are routable
ip link delete docker0 2>/dev/null || true
docker network connect "kind" "${CONTAINER_NAME}" 2>/dev/null || true
echo "Connected to Kind network. Routes:"
ip route show || true

mkdir -p "${HOME}/.kube"
kind get kubeconfig --name "${KIND_CLUSTER_NAME}" > "${HOME}/.kube/config"
[ -s "${HOME}/.kube/config" ] || { echo "ERROR: kubeconfig is empty — Kind cluster did not start"; exit 1; }
sed -i "s|https://0\.0\.0\.0:|https://${DOCKER_GATEWAY}:|g" "${HOME}/.kube/config"
sed -i "s|https://127\.0\.0\.1:|https://${DOCKER_GATEWAY}:|g" "${HOME}/.kube/config"
sed -i '/certificate-authority-data:/a\    insecure-skip-tls-verify: true' "${HOME}/.kube/config"
sed -i '/certificate-authority-data:/d' "${HOME}/.kube/config"
echo "Kubeconfig server → $(grep 'server:' "${HOME}/.kube/config" | head -1)"
export KUBECONFIG="${HOME}/.kube/config"

KIND_NODE_IP=$(docker inspect "${KIND_CLUSTER_NAME}-control-plane" \
    --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null || true)
if [ -z "${KIND_NODE_IP}" ]; then
    KIND_NODE_IP="${KIND_CLUSTER_NAME}-control-plane"
else
    echo "${KIND_NODE_IP}  ${KIND_CLUSTER_NAME}-control-plane" >> /etc/hosts
fi

echo "Waiting for API server to be reachable..."
for i in $(seq 1 90); do
    if kubectl cluster-info --context "kind-${KIND_CLUSTER_NAME}" &>/dev/null; then
        echo "  API server ready after $((i*5))s"
        break
    fi
    echo "  attempt ${i}/90 — not ready yet, waiting 5s..."
    sleep 5
    if [ "${i}" -eq 90 ]; then
        echo "ERROR: API server not reachable after 450s. Aborting."
        exit 1
    fi
done
kubectl cluster-info --context "kind-${KIND_CLUSTER_NAME}"

kubectl patch daemonset kindnet -n kube-system --type='json' -p='[
  {"op":"replace","path":"/spec/template/spec/containers/0/resources/limits/memory","value":"256Mi"},
  {"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/memory","value":"64Mi"}
]' 2>/dev/null || true

for i in $(seq 1 60); do
    STATUS=$(kubectl get node "${KIND_CLUSTER_NAME}-control-plane" \
        --no-headers 2>/dev/null | awk '{print $2}')
    [ "${STATUS}" = "Ready" ] && break
    sleep 5
done
kubectl get nodes

echo "Waiting for kube-proxy to be Running..."
for i in $(seq 1 60); do
    KP_STATUS=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy \
        --no-headers 2>/dev/null | awk '{print $3}' | head -1)
    echo "  kube-proxy status: ${KP_STATUS}"
    [ "${KP_STATUS}" = "Running" ] && break
    sleep 5
done
kubectl get pods -n kube-system -l k8s-app=kube-proxy

_kind_load() {
    local img="$1"
    echo "Loading ${img} into Kind node..."
    docker exec "${KIND_CLUSTER_NAME}-control-plane" \
        crictl rmi "${img}" 2>/dev/null || true
    docker exec "${KIND_CLUSTER_NAME}-control-plane" \
        ctr --namespace=k8s.io images rm "${img}" 2>/dev/null || true
    docker save "${img}" | \
        docker exec -i "${KIND_CLUSTER_NAME}-control-plane" \
            ctr --namespace=k8s.io images import \
                --snapshotter=native \
                --platform linux/ppc64le \
                --local \
                -
}

_kind_load "${NGINX_IC_IMAGE}"
_kind_load "${BACKEND_IMAGE}"
_kind_load "${NGINX_ALPINE_IMAGE}"
_kind_load "${NGINX_PLAIN_IMAGE}"
_kind_load "coredns/coredns:1.14.7"
_kind_load "ghcr.io/nginx/kic-test-tcp-server:0.2.6"
_kind_load "ghcr.io/nginx/kic-test-udp-server:0.2.6"
_kind_load "ghcr.io/nginx/kic-test-grpc-server:0.2.6"
for _img in "${CERTMANAGER_IMAGES[@]}"; do
    _kind_load "${_img}"
done
_kind_load "${EXTERNALDNS_IMAGE}"

# Background diagnostic
(
    for _i in $(seq 1 15); do
        sleep 60
        echo "===== [DIAG] pod status ====="
        kubectl get pods -A 2>/dev/null || true
        echo "===== [DIAG] nginx-ingress events ====="
        kubectl get events -n nginx-ingress --sort-by='.lastTimestamp' 2>/dev/null || true
        echo "===== [DIAG] nginx-ingress pod logs (current) ====="
        kubectl logs -n nginx-ingress -l app=nginx-ingress --tail=100 2>/dev/null || true
    done
) &
DIAG_PID=$!

# ---------------------------------------------------------------------------
# Python venv + dependencies
# ---------------------------------------------------------------------------
cd "${REPO_ROOT}/tests"
${PYTHON3} -m venv venv
source venv/bin/activate
pip install --upgrade pip

pip install \
    pytest \
    pytest-html \
    pytest-metadata \
    flaky \
    kubernetes \
    requests \
    urllib3 \
    pyopenssl \
    cryptography \
    pyyaml \
    jinja2 \
    google-auth \
    cachetools \
    docker \
    durationpy \
    forcediphttpsadapter \
    gprof2dot \
    greenlet \
    more-itertools \
    protobuf \
    pyjwt

echo "-------------------- Installing grpcio from IBM devpi ---------------"
pip install \
    --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url "${IBM_WHEELS}" \
    grpcio==1.80.0 || true

# ---------------------------------------------------------------------------
# E2E Tests
# ---------------------------------------------------------------------------
PYTEST_COMMON=(
    --image="${NGINX_IC_IMAGE}"
    --image-pull-policy=Never
    --ic-type=nginx-ingress
    --service=nodeport
    --node-ip="${KIND_NODE_IP}"
    --context="kind-${KIND_CLUSTER_NAME}"
    --ignore-glob=suite/test_oidc*.py
    suite/
)

run_marker() {
    local label="$1"; local marker="$2"
    echo "===== Running: ${label} ====="
    if ! pytest -v --show-ic-logs=yes "${PYTEST_COMMON[@]}" -m "${marker}"; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
        kill "${DIAG_PID}" 2>/dev/null || true
        kind delete cluster --name "${KIND_CLUSTER_NAME}"
        deactivate
        exit 2
    fi
}

# ---------------------------------------------------------------------------
# ingresses
# ---------------------------------------------------------------------------
run_marker "ingresses 1/2" \
    "ingresses and not annotations and not basic_auth and not hsts and not watch_namespace and not wildcard_tls and not custom_http_errors"
run_marker "ingresses 2/2" \
    "annotations or basic_auth or hsts or watch_namespace or wildcard_tls or custom_http_errors"

# ---------------------------------------------------------------------------
# policies
# ---------------------------------------------------------------------------
run_marker "policies 1/5" \
    "policies and not policies_rl and not policies_ac and not policies_jwt and not policies_mtls and not policies_cache and not policies_cors and not policies_external_auth"
run_marker "policies 2/5" \
    "policies_cors"
run_marker "policies 3/5" \
    "policies_external_auth and not policies_external_auth_tls and not policies_external_auth_vs"
run_marker "policies 4/5" \
    "policies_external_auth_vs and not policies_external_auth_tls"
run_marker "policies 5/5" \
    "policies_external_auth_tls"
run_marker "policies ac+jwt" \
    "policies_ac or policies_jwt"
run_marker "policies rl" \
    "policies_rl"
run_marker "policies mtls+cache" \
    "policies_mtls or policies_cache"

# ---------------------------------------------------------------------------
# TS
# ---------------------------------------------------------------------------
run_marker "TS" "ts"

# ---------------------------------------------------------------------------
# VSR
# ---------------------------------------------------------------------------
run_marker "VSR 1/3" \
    "vsr and not vsr_upstream and not vsr_grpc and not vsr_status and not vsr_canary and not vsr_routing and not vsr_api and not vsr_redirects and not vsr_rewrite and not vsr_canned and not vsr_basic and not vsr_multi_regex"
run_marker "VSR 2/3" \
    "vsr_basic or vsr_canned or vsr_rewrite or vsr_redirects or vsr_upstream or vsr_multi_regex"
run_marker "VSR 3/3" \
    "vsr_routing or vsr_canary or vsr_status or vsr_api or vsr_grpc"

# ---------------------------------------------------------------------------
# VS
# ---------------------------------------------------------------------------
run_marker "VS 1/4" \
    "vs and not vs_ipv6 and not vs_rewrite and not vs_responses and not vs_grpc and not vs_redirects and not vs_externalname and not vs_externaldns and not vs_certmanager and not vs_api and not vs_backup and not vs_use_cluster_ip and not vs_canary and not vs_upstream and not vs_config_map"
run_marker "VS 2/4" \
    "vs_grpc or vs_redirects or vs_externalname or vs_externaldns or vs_api or vs_backup or vs_use_cluster_ip or vs_canary or vs_upstream or vs_config_map"
run_marker "VS 3/4" \
    "vs_responses or vs_ipv6 or vs_rewrite"
run_marker "VS 4/4" \
    "vs_certmanager"

# ---------------------------------------------------------------------------
# otel — no skip_for_nginx_oss; runs against OSS IC
# ---------------------------------------------------------------------------
run_marker "otel" "otel"

# ---------------------------------------------------------------------------
# agent v3 — /usr/bin/nginx-agent and /etc/nginx-agent/nginx-agent.conf are in the IC image
# ---------------------------------------------------------------------------
run_marker "agent 1/1" "agentv3"

kill "${DIAG_PID}" 2>/dev/null || true
kind delete cluster --name "${KIND_CLUSTER_NAME}"
deactivate

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
exit 0
