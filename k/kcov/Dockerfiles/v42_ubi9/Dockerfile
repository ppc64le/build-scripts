FROM registry.access.redhat.com/ubi9/ubi as builder

ARG PACKAGE_VERSION=v42

RUN yum install -y git gcc gcc-c++ make wget cmake elfutils-libelf libcurl-devel gcc-toolset-12-binutils-devel-2.38-19.el9 elfutils zlib-devel openssl-devel libzstd && \
    yum install -y https://dl.fedoraproject.org/pub/epel/9/Everything/ppc64le/Packages/e/epel-release-9-7.el9.noarch.rpm && \
    wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/libzstd-devel-1.5.1-2.el9.ppc64le.rpm && \
    rpm -i libzstd-devel-1.5.1-2.el9.ppc64le.rpm && \
    yum install binutils rust-lzma-sys+default-devel.noarch -y && \
    wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/elfutils-libelf-devel-0.189-3.el9.ppc64le.rpm && \
    rpm -i elfutils-libelf-devel-0.189-3.el9.ppc64le.rpm && \
    wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/elfutils-devel-0.189-3.el9.ppc64le.rpm && \
    rpm -i elfutils-devel-0.189-3.el9.ppc64le.rpm

RUN git clone https://github.com/SimonKagstrom/kcov && \
    cd kcov && \
    git checkout $PACKAGE_VERSION && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make && make install

FROM registry.access.redhat.com/ubi9/ubi

RUN  yum clean all

COPY --from=builder /usr/local/bin/kcov* /usr/local/bin/
COPY --from=builder /usr/local/share/doc/kcov /usr/local/share/doc/kcov

CMD ["/usr/local/bin/kcov"]
