ARG wdir=/tmp

FROM registry.access.redhat.com/ubi8/ubi:8.7 as build

ENV ENVOY_PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/e/envoy/envoy_1.29.3.patch
ENV PACKAGE_NAME=envoy
ENV PACKAGE_VERSION=1.29.3
ENV PACKAGE_ORG=envoyproxy
ENV PACKAGE_URL=https://github.com/envoyproxy/envoy/
ENV BAZEL_VERSION=6.3.2
ARG wdir

#Install deps
RUN yum install -y cmake libatomic libstdc++ libstdc++-static libtool lld patch python3-pip openssl-devel libffi-devel unzip wget zip java-11-openjdk-devel git gcc-c++ xz file binutils rust cargo diffutils sudo \
    && rpm -ivh https://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/Packages/ninja-build-1.8.2-1.el8.ppc64le.rpm \
	https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/aspell-0.60.6.1-22.el8.ppc64le.rpm \
	https://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/aspell-en-2017.08.24-2.el8.ppc64le.rpm

#Add user
RUN useradd envoy

#Copy patch
RUN wget $ENVOY_PATCH
RUN cp ${PACKAGE_NAME}_${PACKAGE_VERSION}.patch $wdir/

#Run build as user envoy
RUN sudo -u envoy -- bash <<EOF
    set -ex
    cd $wdir
    git clone ${PACKAGE_URL} 
    cd ${PACKAGE_NAME} && git checkout v${PACKAGE_VERSION}
    git apply $wdir/${PACKAGE_NAME}_${PACKAGE_VERSION}.patch 

    cd $wdir 
    export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*') 
    export JRE_HOME=${JAVA_HOME}/jre 
    export PATH=${JAVA_HOME}/bin:$PATH 
    mkdir bazel 
    cd bazel 
    wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-$BAZEL_VERSION-dist.zip 
    unzip bazel-$BAZEL_VERSION-dist.zip 
    rm -rf bazel-$BAZEL_VERSION-dist.zip 
    ./compile.sh  
    export PATH=$PATH:$wdir/bazel/output 

    cd $wdir 
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz 
    tar -xvf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz 
    rm -rf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz 

    cd $wdir/${PACKAGE_NAME}
    bazel/setup_clang.sh $wdir/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/ 
    bazel build -c opt --config=libc++ envoy --config=clang --define=wasm=disabled --cxxopt=-fpermissive 

    cp $wdir/envoy/bazel-bin/source/exe/envoy-static $wdir/envoy/envoy-static
    chmod -R 755 $wdir/envoy
    strip -s $wdir/envoy/envoy-static
EOF

RUN cd $wdir && git clone https://github.com/ncopa/su-exec && cd su-exec && make su-exec && cp su-exec /usr/bin


FROM registry.access.redhat.com/ubi8/ubi:8.7

ARG wdir

#Copy from build stage
RUN mkdir -p /etc/envoy
COPY --from=build /usr/bin/su-exec /usr/bin/
COPY --from=build $wdir/envoy/VERSION.txt /etc/envoy 
COPY --from=build $wdir/envoy/configs/envoyproxy_io_proxy.yaml /etc/envoy/envoy.yaml
COPY --from=build $wdir/envoy/ci/docker-entrypoint.sh /docker-entrypoint.sh
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
