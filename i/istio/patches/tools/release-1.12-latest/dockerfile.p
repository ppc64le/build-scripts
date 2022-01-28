diff --git a/docker/build-tools/Dockerfile b/docker/build-tools/Dockerfile
index 317c1ea..f5f2540 100644
--- a/docker/build-tools/Dockerfile
+++ b/docker/build-tools/Dockerfile
@@ -101,6 +101,7 @@ RUN set -eux; \
     case $(uname -m) in \
         x86_64) export PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-x86_64.zip;; \
         aarch64) export PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-aarch_64.zip;; \
+        ppc64le) export PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-ppcle_64.zip;; \
         *) echo "unsupported architecture"; exit 1 ;; \
     esac; \
     \
@@ -110,9 +111,14 @@ RUN set -eux; \
     chmod +x ${OUTDIR}/usr/bin/protoc
 
 # Install gh
-ADD https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.deb /tmp/
-RUN dpkg -i /tmp/gh_${GH_VERSION}_linux_${TARGETARCH}.deb
-RUN mv /usr/bin/gh ${OUTDIR}/usr/bin
+RUN set -eux; \
+    \
+    case $(uname -m) in \
+        ppc64le) echo "gh not available on ppc64le" ;; \
+        *) wget -nv -O "/tmp/gh_${GH_VERSION}_linux_${TARGETARCH}.deb" "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.deb"; \
+        dpkg -i /tmp/gh_${GH_VERSION}_linux_${TARGETARCH}.deb ; \
+        mv /usr/bin/gh ${OUTDIR}/usr/bin;; \
+    esac;
 
 # Build and install a bunch of Go tools
 RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@${GOLANG_PROTOBUF_VERSION}
@@ -188,11 +194,20 @@ RUN git clone --depth 1 https://github.com/kubernetes-sigs/boskos --branch maste
   cd .. && rm -rf boskos
 
 # Compress the Go tools and put them in their final location
-ADD https://github.com/upx/upx/releases/download/v${UPX_VERSION}/upx-${UPX_VERSION}-${TARGETARCH}_linux.tar.xz /tmp
-RUN tar -xJf upx-${UPX_VERSION}-${TARGETARCH}_linux.tar.xz -C /tmp
-RUN mv /tmp/upx-${UPX_VERSION}-${TARGETARCH}_linux/upx /usr/bin
-RUN upx --lzma /tmp/go/bin/*
-RUN mv /tmp/go/bin/* ${OUTDIR}/usr/bin
+RUN set -eux; \
+    \
+    case $(uname -m) in \
+        x86_64) export UPX_FILE=upx-${UPX_VERSION}-${TARGETARCH}_linux;; \
+        aarch64) export UPX_FILE=upx-${UPX_VERSION}-${TARGETARCH}_linux;; \
+        ppc64le) export UPX_FILE=upx-${UPX_VERSION}-powerpc64le_linux;; \
+        *) echo "unsupported architecture"; exit 1 ;; \
+    esac; \
+    \
+    wget -nv -O "/tmp/${UPX_FILE}.tar.xz" "https://github.com/upx/upx/releases/download/v${UPX_VERSION}/${UPX_FILE}.tar.xz"; \
+    tar -xJf ${UPX_FILE}.tar.xz -C /tmp; \
+    mv /tmp/${UPX_FILE}/upx /usr/bin; \
+    upx --lzma /tmp/go/bin/*; \
+    mv /tmp/go/bin/* ${OUTDIR}/usr/bin
 
 # Add gen-release-notes templates to filesystem
 RUN mkdir -p ${OUTDIR}/usr/share/gen-release-notes
@@ -202,9 +217,14 @@ ADD https://raw.githubusercontent.com/istio/tools/master/cmd/gen-release-notes/t
 RUN chmod -R 555 ${OUTDIR}/usr/share/gen-release-notes
 
 # ShellCheck linter
-RUN wget -O "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz" "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz"
-RUN tar -xJf "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz" -C /tmp
-RUN mv /tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck ${OUTDIR}/usr/bin
+RUN set -eux; \
+    \
+    case $(uname -m) in \
+        ppc64le) echo "ShellCheck not available on ppc64le" ;; \
+        *) wget -O "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz" "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz"; \
+        tar -xJf "/tmp/shellcheck-${SHELLCHECK_VERSION}.linux.$(uname -m).tar.xz" -C /tmp; \
+        mv /tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck ${OUTDIR}/usr/bin;; \
+    esac;
 
 # Hadolint linter
 ADD https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64 ${OUTDIR}/usr/bin/hadolint
@@ -216,13 +236,15 @@ RUN set -eux; \
     case $(uname -m) in \
         x86_64) export HUGO_TAR=hugo_${HUGO_VERSION}_Linux-64bit.tar.gz;; \
         aarch64) export HUGO_TAR=hugo_${HUGO_VERSION}_Linux-ARM64.tar.gz;; \
+        ppc64le) export HUGO_TAR=""; echo "Hugo not available on ppc64le";; \
         *) echo "unsupported architecture"; exit 1 ;; \
     esac; \
     \
-    wget -O /tmp/${HUGO_TAR} https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_TAR}; \
-    tar -xzvf /tmp/${HUGO_TAR} -C /tmp; \
-
-    mv /tmp/hugo ${OUTDIR}/usr/bin
+    if [ -n "${HUGO_TAR}" ]; then \
+        wget -O "/tmp/${HUGO_TAR}" "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/${HUGO_TAR}"; \
+        tar -xzvf "/tmp/${HUGO_TAR}" -C /tmp; \
+        mv /tmp/hugo ${OUTDIR}/usr/bin; \
+    fi
 
 # Helm version 3
 ADD https://get.helm.sh/helm-${HELM3_VERSION}-linux-${TARGETARCH}.tar.gz /tmp
@@ -241,12 +263,22 @@ ADD https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION
 RUN chmod 555 ${OUTDIR}/usr/bin/kubectl
 
 # GCR docker credential helper
-ADD https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${GCR_AUTH_VERSION}/docker-credential-gcr_linux_${TARGETARCH}-${GCR_AUTH_VERSION}.tar.gz /tmp
-RUN tar -xzf /tmp/docker-credential-gcr_linux_${TARGETARCH}-${GCR_AUTH_VERSION}.tar.gz -C /tmp
-RUN mv /tmp/docker-credential-gcr ${OUTDIR}/usr/bin
+RUN set -eux; \
+    \
+    case $(uname -m) in \
+        ppc64le) echo "GCR docker credential helper not available on ppc64le";; \
+        *) wget -O "/tmp/gcr.tar.gz" "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v${GCR_AUTH_VERSION}/docker-credential-gcr_linux_${TARGETARCH}-${GCR_AUTH_VERSION}.tar.gz"; \
+        tar -xzf /tmp/gcr.tar.gz -C /tmp; \
+        mv /tmp/docker-credential-gcr ${OUTDIR}/usr/bin;; \
+    esac;
 
-RUN wget -O "${OUTDIR}/usr/bin/buf" "https://github.com/bufbuild/buf/releases/download/${BUF_VERSION}/buf-Linux-$(uname -m)" && \
-    chmod 555 "${OUTDIR}/usr/bin/buf"
+RUN set -eux; \
+    \
+    case $(uname -m) in \
+        ppc64le) echo "buf not available on ppc64le";; \
+        *) wget -O "${OUTDIR}/usr/bin/buf" "https://github.com/bufbuild/buf/releases/download/${BUF_VERSION}/buf-Linux-$(uname -m)" && \
+        chmod 555 ${OUTDIR}/usr/bin/buf;; \
+    esac;
 
 # Install su-exec which is a tool that operates like sudo without the overhead
 ADD https://github.com/ncopa/su-exec/archive/v${SU_EXEC_VERSION}.tar.gz /tmp
@@ -255,28 +287,41 @@ WORKDIR /tmp/su-exec-${SU_EXEC_VERSION}
 RUN make
 RUN cp -a su-exec ${OUTDIR}/usr/bin
 
-ADD https://github.com/GoogleContainerTools/kpt/releases/download/${KPT_VERSION}/kpt_linux_${TARGETARCH} ${OUTDIR}/usr/bin/kpt
-RUN chmod 555 ${OUTDIR}/usr/bin/kpt
+# kpt
+RUN set -eux; \
+    \
+    case $(uname -m) in \
+        ppc64le) echo "kpt not available on ppc64le";; \
+        *) wget -O "${OUTDIR}/usr/bin/kpt" "https://github.com/GoogleContainerTools/kpt/releases/download/${KPT_VERSION}/kpt_linux_${TARGETARCH}" && \
+        chmod 555 ${OUTDIR}/usr/bin/kpt;; \
+    esac;
 
 # Install gcloud command line tool
 # Install gcloud beta component
 RUN set -eux; \
     \
     case $(uname -m) in \
+        ppc64le)  export GCLOUD_TAR_FILE="" ;; \
         x86_64)  export GCLOUD_TAR_FILE="google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz" ;; \
         aarch64) export GCLOUD_TAR_FILE="google-cloud-sdk-${GCLOUD_VERSION}-linux-arm.tar.gz" ;; \
         *) echo "unsupported architecture"; exit 1 ;; \
     esac; \
     \
-    wget "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${GCLOUD_TAR_FILE}"; \
-    tar -xzvf ."/${GCLOUD_TAR_FILE}" -C "${OUTDIR}/usr/local" && rm "${GCLOUD_TAR_FILE}"; \
-    ${OUTDIR}/usr/local/google-cloud-sdk/bin/gcloud components install beta --quiet; \
-    ${OUTDIR}/usr/local/google-cloud-sdk/bin/gcloud components install alpha --quiet; \
-    rm -rf /usr/local/google-cloud-sdk/.install/.backup
+    if [ -n "${GCLOUD_TAR_FILE}" ]; then \
+        wget "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${GCLOUD_TAR_FILE}"; \
+        tar -xzvf ."/${GCLOUD_TAR_FILE}" -C "${OUTDIR}/usr/local" && rm "${GCLOUD_TAR_FILE}"; \
+        ${OUTDIR}/usr/local/google-cloud-sdk/bin/gcloud components install beta --quiet; \
+        ${OUTDIR}/usr/local/google-cloud-sdk/bin/gcloud components install alpha --quiet; \
+        rm -rf /usr/local/google-cloud-sdk/.install/.backup; \
+    fi    
 
 # Install cosign (for signing build artifacts) and verify signature
 SHELL ["/bin/bash", "-o", "pipefail", "-c"]
 RUN set -eux; \
+    \
+    case $(uname -m) in \
+        ppc64le) echo "cosign not supported on ppc64le"; exit 0;; \
+    esac; \
     ${OUTDIR}/usr/local/google-cloud-sdk/bin/gsutil -q cp gs://cosign-releases/${COSIGN_VERSION}/cosign-linux-amd64 /tmp/cosign \
     && ${OUTDIR}/usr/local/google-cloud-sdk/bin/gsutil -q cat gs://cosign-releases/${COSIGN_VERSION}/cosign-linux-amd64.sig | base64 -d > /tmp/cosign.sig \
     && wget -O /tmp/cosign-pubkey https://raw.githubusercontent.com/sigstore/cosign/main/release/release-cosign.pub \
@@ -320,6 +365,7 @@ RUN set -eux; \
     case $(uname -m) in \
         x86_64) export NODEJS_TAR=node-v${NODEJS_VERSION}-linux-x64.tar.gz;; \
         aarch64) export NODEJS_TAR=node-v${NODEJS_VERSION}-linux-arm64.tar.gz;; \
+        ppc64le) export NODEJS_TAR=node-v${NODEJS_VERSION}-linux-ppc64le.tar.gz;; \
         *) echo "unsupported architecture"; exit 1 ;; \
     esac; \
     wget -O /tmp/${NODEJS_TAR} https://nodejs.org/download/release/v${NODEJS_VERSION}/${NODEJS_TAR}; \
@@ -429,6 +475,16 @@ RUN python3 -m pip install --no-cache-dir yamllint==${YAMLLINT_VERSION}
 RUN python3 -m pip install --no-cache-dir requests==${REQUESTS_VERSION}
 RUN python3 -m pip install --no-cache-dir protobuf==${PYTHON_PROTOBUF_VERSION}
 RUN python3 -m pip install --no-cache-dir PyYAML==${PYYAML_VERSION}
+# Add packages required to build jwcrypto dependencies on ppc64le
+RUN set -eux; \
+    \
+    case $(uname -m) in \
+        ppc64le) apt-get update && apt-get install -y --no-install-recommends \
+            rustc \
+            cargo \
+            python3-dev \
+            libssl-dev ;; \
+    esac;
 RUN python3 -m pip install --no-cache-dir jwcrypto==${JWCRYPTO_VERSION}
 
 #############
@@ -439,8 +495,8 @@ FROM ubuntu:focal as base_os_context
 
 ENV DEBIAN_FRONTEND=noninteractive
 
-ENV DOCKER_VERSION=5:20.10.6~3-0~ubuntu-focal
-ENV CONTAINERD_VERSION=1.4.4-1
+ENV DOCKER_VERSION=5:20.10.7~3-0~ubuntu-focal
+ENV CONTAINERD_VERSION=1.4.6-1
 ENV TRIVY_VERSION=0.18.3
 
 ENV OUTDIR=/out
@@ -481,7 +537,14 @@ RUN apt-get update && apt-get install -y --no-install-recommends \
 ADD https://download.docker.com/linux/ubuntu/gpg /tmp/docker-key
 RUN apt-key add /tmp/docker-key
 ARG TARGETARCH
-RUN add-apt-repository "deb [arch=${TARGETARCH}] https://download.docker.com/linux/ubuntu $(lsb_release -sc) stable"
+# Add packages required to build jwcrypto dependencies on ppc64le
+RUN set -eux; \
+    \
+    case ${TARGETARCH} in \
+        ppc64le) export APT_ARCH="ppc64el" ;; \
+        *) export APT_ARCH=${TARGETARCH} ;; \
+    esac; \
+    add-apt-repository "deb [arch=${APT_ARCH}] https://download.docker.com/linux/ubuntu $(lsb_release -sc) stable"
 RUN apt-get update
 RUN apt-get -y install --no-install-recommends docker-ce="${DOCKER_VERSION}" docker-ce-cli="${DOCKER_VERSION}" containerd.io="${CONTAINERD_VERSION}"
 
@@ -495,6 +558,9 @@ RUN set -eux; \
         aarch64) \
             export TRVIY_DEB_NAME="trivy_${TRIVY_VERSION}_Linux-ARM64.deb"; \
             ;; \
+        ppc64le) \
+            export TRVIY_DEB_NAME="trivy_${TRIVY_VERSION}_Linux-PPC64LE.deb"; \
+            ;; \
         *) echo "unsupported architecture"; exit 1 ;; \
     esac; \
     wget -O "/tmp/${TRVIY_DEB_NAME}" "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/${TRVIY_DEB_NAME}"; \
@@ -613,6 +679,7 @@ ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
 
 FROM ubuntu:xenial AS clang_context_amd64
 FROM ubuntu:bionic AS clang_context_arm64
+FROM ubuntu:bionic AS clang_context_ppc64le
 # hadolint ignore=DL3006
 FROM clang_context_${TARGETARCH} AS clang_context
 
@@ -638,6 +705,9 @@ RUN set -eux; \
         aarch64)  \
                export LLVM_ARCHIVE=clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu \
                export LLVM_ARTIFACT=clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu;; \
+        ppc64le)  \
+               export LLVM_ARCHIVE=clang+llvm-${LLVM_VERSION}-powerpc64le-linux-ubuntu-18.04 \
+               export LLVM_ARTIFACT=clang+llvm-${LLVM_VERSION}-powerpc64le-linux-ubuntu-18.04;; \
         *) echo "unsupported architecture"; exit 1 ;; \
     esac; \
     \
@@ -683,6 +753,7 @@ RUN set -eux; \
 
 FROM ubuntu:xenial AS bazel_context_amd64
 FROM ubuntu:bionic AS bazel_context_arm64
+FROM ubuntu:bionic AS bazel_context_ppc64le
 # hadolint ignore=DL3006
 FROM bazel_context_${TARGETARCH} AS bazel_context
 
@@ -700,9 +771,17 @@ RUN apt-get update && apt-get install -y --no-install-recommends \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
 
-RUN wget ${BAZELISK_URL}
-RUN chmod +x ${BAZELISK_BIN}
-RUN mv ${BAZELISK_BIN} /usr/local/bin/bazel
+RUN set -eux; \
+    case $(uname -m) in \
+        ppc64le) \
+            export BAZEL_RELEASE=4.1.0; \
+            wget -O /usr/local/bin/bazel --no-check-certificate https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_16.04/bazel_bin_ppc64le_${BAZEL_RELEASE}; \
+            chmod +x /usr/local/bin/bazel;; \
+        *) \
+            wget ${BAZELISK_URL}; \
+            chmod +x ${BAZELISK_BIN}; \
+            mv ${BAZELISK_BIN} /usr/local/bin/bazel;; \
+    esac
 
 ########################
 # Final image for proxy
@@ -712,6 +791,8 @@ FROM ubuntu:xenial AS build_env_proxy_amd64
 ENV UBUNTU_RELEASE_CODE_NAME=xenial
 FROM ubuntu:bionic AS build_env_proxy_arm64
 ENV UBUNTU_RELEASE_CODE_NAME=bionic
+FROM ubuntu:bionic AS build_env_proxy_ppc64le
+ENV UBUNTU_RELEASE_CODE_NAME=bionic
 # hadolint ignore=DL3006
 FROM build_env_proxy_${TARGETARCH} AS build_env_proxy
 
@@ -723,8 +804,8 @@ LABEL "io.istio.repo"="https://github.com/istio/tools"
 LABEL "io.istio.version"="${VERSION}"
 
 # Docker
-ENV DOCKER_VERSION=5:20.10.6~3-0~ubuntu-${UBUNTU_RELEASE_CODE_NAME}
-ENV CONTAINERD_VERSION=1.4.4-1
+ENV DOCKER_VERSION=5:20.10.7~3-0~ubuntu-${UBUNTU_RELEASE_CODE_NAME}
+ENV CONTAINERD_VERSION=1.4.6-1
 
 # General
 ENV HOME=/home
@@ -779,6 +860,14 @@ ADD https://download.docker.com/linux/ubuntu/gpg /tmp/docker-key
 RUN apt-key add /tmp/docker-key
 ARG TARGETARCH
 RUN add-apt-repository "deb [arch=${TARGETARCH}] https://download.docker.com/linux/ubuntu ${UBUNTU_RELEASE_CODE_NAME} stable"
+RUN set -eux; \
+    \
+    case ${TARGETARCH} in \
+        ppc64le) export APT_ARCH="ppc64el" ;; \
+        *) export APT_ARCH=${TARGETARCH} ;; \
+    esac; \
+    add-apt-repository "deb [arch=${APT_ARCH}] https://download.docker.com/linux/ubuntu ${UBUNTU_RELEASE_CODE_NAME} stable"
+# hadolint ignore=DL3009
 RUN apt-get update && apt-get -y install --no-install-recommends \
     docker-ce="${DOCKER_VERSION}" \
     docker-ce-cli="${DOCKER_VERSION}" \
@@ -818,6 +907,19 @@ RUN apt-get update && apt-get install -y --no-install-recommends \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
 
+# JDK required for bazel on ppc64
+# hadolint ignore=DL3008
+RUN set -eux; \
+    \
+    case $(uname -m) in \
+        ppc64le) \
+            apt-get update && apt-get install -y --no-install-recommends \
+            openjdk-8-jdk \
+            && apt-get clean \
+            && rm -rf /var/lib/apt/lists/* ;; \
+        *) echo "skip" ;; \
+    esac;
+
 COPY --from=binary_tools_context /out/ /
 COPY --from=binary_tools_context /usr/local/go /usr/local/go
 COPY --from=gn_context /gn/gn /usr/local/bin/gn
