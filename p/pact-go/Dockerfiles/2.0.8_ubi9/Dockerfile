FROM registry.access.redhat.com/ubi9/ubi:9.3

ARG PACKAGE_VERSION=v2.0.8

# Install dependencies
RUN yum install wget -y && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/ && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/ && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/ && \
    wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official && \
    mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

RUN yum install -y git wget gcc gcc-c++ make cmake autoconf automake libtool pkgconf-pkg-config info json-c python3-devel python3-pytest python3-sphinx gzip tar bzip2 zip unzip zlib-devel protobuf protobuf-devel protobuf-c protobuf-c-devel  java-11-openjdk-devel  libffi-devel clang clang-devel llvm-devel llvm-static clang-libs readline ncurses-devel pcre-devel pcre2-devel libcap rpm-build systemd-devel groff-base platform-python-devel readline-devel texinfo net-snmp-devel pkgconfig json-c-devel pam-devel bison flex c-ares-devel  libcap-devel


RUN wget https://go.dev/dl/go1.21.6.linux-ppc64le.tar.gz && \
    tar -C  /usr/local -xf go1.21.6.linux-ppc64le.tar.gz && \
    export GOROOT=/usr/local/go && \
    export GOPATH=$HOME && \
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
    git clone https://github.com/pact-foundation/pact-go && \
    cd pact-go && \
    git checkout $PACKAGE_VERSION && \
    ls -l && \
    go build ./...

WORKDIR /pact-go/build/pact-go

CMD ["/bin/bash"]
