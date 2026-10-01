########################################################################################################################
# Docker build command:
# docker build -t bazel .
# Docker run command:
# docker run -it bazel
########################################################################################################################

FROM registry.access.redhat.com/ubi8/ubi:latest

LABEL name="bazel" \
      maintainer="sethp@us.ibm.com" \
      vendor="bazel" \
      version="0.29.1" \
      release="1" \
      summary="Red Hat UBI  bazel" \
      description="Red Hat UBI bazel Application"

RUN yum update -y \
    && yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel wget autoconf libtool curl \
       make unzip zip git gcc-c++ python3 \
    && export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk \
    && export JRE_HOME=${JAVA_HOME}/jre \
    && export PATH=${JAVA_HOME}/bin:$PATH \
    && wdir=`pwd` \
    && mkdir bazel && cd bazel \
    && wget https://github.com/bazelbuild/bazel/releases/download/0.29.1/bazel-0.29.1-dist.zip \
    && unzip bazel-0.29.1-dist.zip && rm bazel-0.29.1-dist.zip \
    && chmod -R +w .  \
    && mkdir /licenses && cp LICENSE /licenses/licensing.txt \
    && sed -i -e '12 a config_setting( \n\tname = "linux_ppc",\n\tvalues = {"cpu": "ppc"},\n\tvisibility = ["//visibility:public"],\n)\n' ./src/conditions/BUILD \
    && sed -i -e '530 a "//src/conditions:linux_ppc": "*.so *.jnilib *.dll",' ./third_party/BUILD


RUN ln -s $(which python3) /usr/local/bin/python \
    && cd $wdir/bazel \
    && env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh \
    && export PATH=$PATH:$wdir/bazel/output \
    && yum remove -y wget autoconf libtool make unzip zip git gcc-c++ \
    && yum -y autoremove 

RUN groupadd bazel && useradd -r -g bazel bazel -m -d /home/bazel/

USER bazel

WORKDIR /home/bazel

ENV PATH $PATH:$wdir/bazel/output

CMD ["/bin/bash"]


