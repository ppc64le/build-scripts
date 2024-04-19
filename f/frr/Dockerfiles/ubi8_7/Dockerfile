FROM registry.access.redhat.com/ubi8:8.7

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_VERSION=frr-9.0.1

ENV PATH=/usr/local/bin:$PATH

RUN yum install -y wget yum-utils && \
    yum-config-manager --add-repo https://vault.centos.org/8.5.2111/AppStream/ppc64le/os/ && \
    yum-config-manager --add-repo https://vault.centos.org/8.5.2111/Devel/ppc64le/os/ && \
    yum-config-manager --add-repo https://vault.centos.org/8.5.2111/PowerTools/ppc64le/os/ && \
    yum-config-manager --add-repo https://vault.centos.org/8.5.2111/BaseOS/ppc64le/os/ && \
    yum-config-manager --add-repo https://vault.centos.org/8.5.2111/HighAvailability/ppc64le/os/ && \
    yum-config-manager --add-repo https://vault.centos.org/8.5.2111/centosplus/ppc64le/os/ && \
    yum-config-manager --add-repo https://vault.centos.org/8.5.2111/cr/ppc64le/os/ && \
    yum-config-manager --add-repo https://vault.centos.org/8.5.2111/extras/ppc64le/os/ && \
    yum-config-manager --add-repo https://vault.centos.org/8.5.2111/fasttrack/ppc64le/os/ 

RUN wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official && \
    mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official

RUN yum install -y git wget gcc gcc-c++ make cmake autoconf automake libtool pkgconf-pkg-config.ppc64le info.ppc64le json-c.ppc64le python39-devel.ppc64le  gzip tar bzip2 zip unzip zlib-devel protobuf-c.ppc64le  java-11-openjdk-devel  libffi-devel clang clang-devel llvm-devel llvm-static clang-libs readline.ppc64le ncurses-devel.ppc64le  pcre2-devel.ppc64le libcap.ppc64le  && \
    yum install -y rpm-build git autoconf pcre-devel systemd-devel automake libtool make readline info groff-base json-c pam  python3-pytest python39-devel libcap platform-python-devel protobuf-c protobuf protobuf-c-devel protobuf-devel && \
    yum install -y readline-devel texinfo net-snmp-devel pkgconfig json-c-devel pam-devel bison flex c-ares-devel python3-sphinx libcap-devel  protobuf-c-devel && \
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
    git checkout v2.1.4 && \
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
    git checkout frr-9.0.1 && \
    sh bootstrap.sh && \
    ./configure && \
    make 

CMD ["bash"]







