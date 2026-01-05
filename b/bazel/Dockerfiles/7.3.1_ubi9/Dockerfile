FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vipul Ajmera <Vipul.Ajmera@ibm.com>"

ARG PACKAGE_VERSION=7.3.1

RUN yum install -y git wget gcc gcc-c++ zip unzip python3 python3-devel java-21-openjdk-devel

RUN mkdir bazel-dist && \
    cd bazel-dist && \
    wget https://github.com/bazelbuild/bazel/releases/download/${PACKAGE_VERSION}/bazel-${PACKAGE_VERSION}-dist.zip && \
    unzip bazel-${PACKAGE_VERSION}-dist.zip && \
    env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh && \
    cp output/bazel /usr/local/bin && \
    export PATH=/usr/local/bin:$PATH && \
    cd ..

RUN git clone https://github.com/bazelbuild/bazel.git && \
    cd bazel && \
    git checkout $PACKAGE_VERSION && \
    bazel build //src:bazel-dev 

CMD ["/bin/bash"]




