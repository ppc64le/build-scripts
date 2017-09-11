FROM ppc64le/ubuntu:16.04
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y openjdk-8-jdk wget autoconf libtool curl \
        make unzip zip git g++ && \
    export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el && \
    export JRE_HOME=${JAVA_HOME}/jre && \
    export PATH=${JAVA_HOME}/bin:$PATH && \
    wdir=`pwd` && \
    mkdir bazel && cd bazel && \
    wget https://github.com/bazelbuild/bazel/releases/download/0.4.5/bazel-0.4.5-dist.zip && \
    unzip bazel-0.4.5-dist.zip && rm bazel-0.4.5-dist.zip && \
    ./compile.sh && \
    export PATH=$PATH:$wdir/bazel/output && \
    apt-get purge -y wget autoconf libtool curl make unzip zip git g++ && \
    apt-get -y autoremove 

ENV PATH $PATH:$wdir/bazel/output
CMD ["/bin/bash"]
