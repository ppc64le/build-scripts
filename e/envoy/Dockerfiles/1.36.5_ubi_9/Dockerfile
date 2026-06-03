ARG wdir=/tmp

FROM registry.access.redhat.com/ubi9/ubi:9.7 as build

RUN yum update -y && yum clean all

ENV PACKAGE_NAME=envoy
ENV PACKAGE_VERSION=1.36.5
ENV ENVOY_PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/envoy/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch
ENV PACKAGE_ORG=envoyproxy
ENV PACKAGE_URL=https://github.com/envoyproxy/envoy/
ARG wdir

#Install centos and epel repos
RUN yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
RUN yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
RUN yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
RUN rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

#Install dependencies
RUN yum install -y \
    cmake \
    libatomic \
    libstdc++ \
    libstdc++-static \
    libtool \
    lld \
    patch \
    openssl-devel \
    libffi-devel \
    unzip \
    wget \
    zip \
    java-21-openjdk-devel \
    git \
    gcc-c++ \
    xz \
    file \
    binutils \
    procps \
    diffutils \
    ninja-build \
    aspell \
    aspell-en \
    sudo \
    python3.12 \
    python3.12-devel \
    python3.12-pip

#Copy patch
RUN wget $ENVOY_PATCH
RUN cp ${PACKAGE_NAME}_${PACKAGE_VERSION}.patch $wdir

#Run build
RUN cd $wdir && \
    git clone ${PACKAGE_URL} && \
    cd ${PACKAGE_NAME} && git checkout v${PACKAGE_VERSION} && \
    git apply $wdir/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch && \
    export BAZEL_VERSION=$(cat .bazelversion) && \
    cd $wdir && \
    export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-21-openjdk-*')  && \
    export JRE_HOME=${JAVA_HOME}/jre  && \
    export PATH=${JAVA_HOME}/bin:$PATH  && \
    mkdir bazel  && \
    cd bazel  && \
    wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-$BAZEL_VERSION-dist.zip  && \
    unzip bazel-$BAZEL_VERSION-dist.zip  && \
    rm -rf bazel-$BAZEL_VERSION-dist.zip  && \
    export BAZEL_DEV_VERSION_OVERRIDE=${BAZEL_VERSION} && \
    env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh  && \
    export PATH=$PATH:$wdir/bazel/output  && \
    cd $wdir  && \
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8.tar.xz  && \
    tar -xvf clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8.tar.xz  && \
    rm -rf clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8.tar.xz  && \
    # LLVM / Clang setup (THIS IS REQUIRED)
    export LLVM_DIR=$wdir/clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8 && \
    export PATH=$LLVM_DIR/bin:$PATH && \
    export CC=$LLVM_DIR/bin/clang && \
    export CXX=$LLVM_DIR/bin/clang++ && \
    export LLVM_CONFIG=$LLVM_DIR/bin/llvm-config && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y && source ~/.cargo/env  && \
    cargo install cross --version 0.2.1  && \
    cd $wdir && \
    git clone https://github.com/bazelbuild/rules_rust  && \
    cd rules_rust  && \
    git checkout 0.56.0  && \
    cd crate_universe  && \
    cross build --release --locked --bin cargo-bazel --target=powerpc64le-unknown-linux-gnu  && \
    export CARGO_BAZEL_GENERATOR_URL=file://$(pwd)/target/powerpc64le-unknown-linux-gnu/release/cargo-bazel  && \
    export CARGO_BAZEL_REPIN=true  && \
    cd $wdir/${PACKAGE_NAME} && \
    bazel/setup_clang.sh $wdir/clang+llvm-18.1.8-powerpc64le-linux-rhel-8.8/  && \
	bazel build //source/exe:envoy   --config=clang-gnu   --define=wasm=disabled   --define=enable_http3=true   --define=boringssl_disable_asm=true   --jobs=8   --local_ram_resources=24000  && \
    cp $wdir/envoy/bazel-bin/source/exe/envoy-static $wdir/envoy/envoy-static && \
    chmod -R 755 $wdir/envoy && \
    strip -s $wdir/envoy/envoy-static

RUN cd $wdir && git clone https://github.com/ncopa/su-exec && cd su-exec && make su-exec && cp su-exec /usr/bin


FROM registry.access.redhat.com/ubi9/ubi:9.7

ARG wdir

RUN yum update -y && yum install -y libatomic && yum clean all

#Copy from build stage
RUN mkdir -p /etc/envoy
COPY --from=build /usr/bin/su-exec /usr/bin/
COPY --from=build $wdir/envoy/VERSION.txt /etc/envoy 
COPY --from=build $wdir/envoy/configs/envoyproxy_io_proxy.yaml /etc/envoy/envoy.yaml
COPY --from=build $wdir/envoy/distribution/docker/docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=build $wdir/envoy/envoy-static /usr/bin/envoy

#Expose port
EXPOSE 9901 10000

#Add user
RUN adduser --system envoy

#Entry point
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

#Cmd
CMD ["envoy", "-c", "/etc/envoy/envoy.yaml"]