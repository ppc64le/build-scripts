FROM registry.access.redhat.com/ubi9:9.3

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_VERSION=frr-10.0

ENV PATH=/usr/local/bin:$PATH

RUN yum install -y wget yum-utils && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/ && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/ && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/ 

RUN wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official && \
    mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

RUN yum install -y git wget gcc gcc-c++ make cmake autoconf automake libtool pkgconf-pkg-config info json-c python3-devel python3-pytest python3-sphinx && \
    yum install -y gzip tar bzip2 zip unzip zlib-devel protobuf protobuf-devel protobuf-c protobuf-c-devel  java-11-openjdk-devel  libffi-devel && \
    yum install -y clang clang-devel llvm-devel llvm-static clang-libs readline ncurses-devel pcre-devel pcre2-devel libcap rpm-build && \
    yum install -y systemd-devel groff-base platform-python-devel readline-devel texinfo net-snmp-devel pkgconfig json-c-devel pam-devel bison && \
    yum install -y flex c-ares-devel  libcap-devel  && \
    pip3 install pytest

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.21.0.9-2.el8.ppc64le
ENV PATH=$JAVA_HOME/bin:$PATH
ENV PROTOC=/usr/local/bin/
ENV PATH=$PROTOC:$PATH
ENV PROTOBUF_C=/protobuf-c/protobuf-c
ENV PATH=$PROTOBUF_C:$PATH

RUN ln -sf usr/bin/python3.9 /usr/bin/python3

RUN git clone https://github.com/CESNET/libyang && \
    cd libyang && \
    git checkout v2.1.128 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    cp /libyang/build/libyang.pc /usr/lib64/pkgconfig && \
    cd ../.. 

RUN python3.9 -m pip install pytest 
ENV LD_LIBRARY_PATH=/usr/local/lib64 

RUN git clone https://github.com/FRRouting/frr && \
    cd frr && \
    git checkout $PACKAGE_VERSION && \
    sh bootstrap.sh && \
    ./configure && \
    make 

CMD ["bash"]







