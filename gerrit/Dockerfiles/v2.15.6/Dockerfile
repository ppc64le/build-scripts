FROM ubuntu:16.04

RUN apt-get update && apt-get install -y sudo && \
    adduser --disabled-password --gecos '' gerrit  && \
    adduser gerrit sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 

USER gerrit
WORKDIR /home/gerrit

RUN sudo apt-get update && \
    sudo apt-get install openjdk-8-jdk gcc wget git autoconf libtool curl make zip unzip maven g++ nodejs python-dev -y  && \
    export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el && \
    mkdir bazel && cd bazel && \
    wget https://github.com/bazelbuild/bazel/releases/download/0.20.0/bazel-0.20.0-dist.zip && \
    unzip bazel-0.20.0-dist.zip && \
    chmod -R +w . &&  ./compile.sh && \
    export PATH=$PATH:`pwd`/output && \
    rm -rf bazel-0.20.0-dist.zip && \
    cd .. && \
    git clone --recursive https://gerrit.googlesource.com/gerrit && \
    cd gerrit && \
    git checkout v2.15.6 && \
    git submodule update  && \
    bazel build release --java_toolchain=@bazel_tools//tools/jdk:toolchain_hostjdk8  --host_java_toolchain=@bazel_tools//tools/jdk:toolchain_hostjdk8 && \
    java -jar bazel-bin/release.war init --batch --dev --install-all-plugins -d ~/gerrit_testsite && \
    git config -f ~/gerrit_testsite/etc/gerrit.config --add container.javaOptions "-Djava.security.egd=file:/dev/./urandom" && \
    cd .. && sudo rm -rf bazel && \
    sudo apt-get purge -y gcc wget autoconf libtool curl make zip unzip maven g++ nodejs python-dev && \
    sudo apt-get autoremove -y   

ENV CANONICAL_WEB_URL=

EXPOSE 29418 8080

VOLUME ["/home/gerrit/gerrit_testsite/git", "/home/gerrit/gerrit_testsite/index", "/home/gerrit/gerrit_testsite/cache", "/home/gerrit/gerrit_testsite/db", "/home/gerrit/gerrit_testsite/etc"]

CMD  git config --file ~/gerrit_testsite/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}" && \
     git config --file ~/gerrit_testsite/etc/gerrit.config noteDb.changes.autoMigrate true && \
    ~/gerrit_testsite/bin/gerrit.sh run
