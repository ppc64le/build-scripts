FROM registry.access.redhat.com/ubi8/ubi:8.4

ENV ENVOY_PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/envoy/envoy_1.25.3.patch
ENV PACKAGE_NAME=envoy
ENV PACKAGE_VERSION=1.25.3
ENV PACKAGE_URL=https://github.com/envoyproxy/envoy/
ENV PYTHON_VERSION=3.10.2
ENV wdir=/tmp

#Build and install
RUN yum install -y cmake libatomic libstdc++ libstdc++-static libtool lld patch python3-pip openssl-devel libffi-devel unzip wget zip java-11-openjdk-devel git gcc-c++ xz file binutils libffi-devel \
    && rpm -ivh https://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/Packages/ninja-build-1.8.2-1.el8.ppc64le.rpm https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/aspell-0.60.6.1-22.el8.ppc64le.rpm https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/aspell-en-2017.08.24-2.el8.ppc64le.rpm \
    && export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*') \
    && export JRE_HOME=${JAVA_HOME}/jre \
    && export PATH=${JAVA_HOME}/bin:$PATH \
    && cd $wdir \
    && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xzf Python-${PYTHON_VERSION}.tgz \
    && rm -rf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions \
    && make -j ${nproc} \
    && make altinstall \
    && ln -sf $(which python3.10) /usr/bin/python3 \
    && ln -sf $(which pip3.10) /usr/bin/pip3 \
    && python3 -V && pip3 -V \
    && cd $wdir \
    && wget $ENVOY_PATCH \
    && git clone ${PACKAGE_URL} \
    && cd ${PACKAGE_NAME} && git checkout v${PACKAGE_VERSION} \
    && BAZEL_VERSION=$(cat .bazelversion) \
    && cd $wdir \
    && mkdir bazel \
    && cd bazel \
    && wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip \
    && unzip bazel-${BAZEL_VERSION}-dist.zip \
    && rm -rf bazel-${BAZEL_VERSION}-dist.zip \
    && ./compile.sh \
    && export PATH=$PATH:$wdir/bazel/output \
    && cd $wdir \
    && wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz \
    && tar -xvf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz \
    && rm -rf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz \
    && cd $wdir/${PACKAGE_NAME} \
    && git apply $wdir/envoy_${PACKAGE_VERSION}.patch \
    && bazel/setup_clang.sh $wdir/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/ \
    && bazel build -c opt envoy --config=clang --cxxopt=-fpermissive \
    && ENVOY_BIN=$wdir/envoy/bazel-bin/source/exe/envoy-static \
    && strip -s $ENVOY_BIN \
    && cp $ENVOY_BIN /usr/bin/envoy \
    && envoy --version \
    && cd $wdir && git clone https://github.com/ncopa/su-exec && cd su-exec && make su-exec && cp su-exec /usr/bin \
    && mkdir -p /etc/envoy && cp $wdir/envoy/VERSION.txt /etc/envoy && cp $wdir/envoy/configs/envoyproxy_io_proxy.yaml /etc/envoy/envoy.yaml \
    && cp $wdir/envoy/ci/docker-entrypoint.sh /docker-entrypoint.sh \
    && rm -rf $wdir/envoy $wdir/bazel $wdir/su-exec $wdir/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4 $HOME/.cache/bazel \
    && yum -y remove cmake libatomic libstdc++-static libtool lld patch python3-pip openssl-devel libffi-devel unzip wget zip java-11-openjdk-devel git gcc-c++ xz file binutils libffi-devel

#Expose port
EXPOSE 9901 10000

#Add user
RUN adduser --system envoy

#Entry point
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

#Cmd
CMD ["envoy", "-c", "/etc/envoy/envoy.yaml"]
