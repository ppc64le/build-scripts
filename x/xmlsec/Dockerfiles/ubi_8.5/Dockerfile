FROM registry.access.redhat.com/ubi8:8.5

ARG PACKAGE_VERSION=1_2_37

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

RUN yum update -y \
    && yum install -y autoconf libtool make openssl-devel libxml2-devel pkgconfig git libxslt-devel diffutils nss-tools wget tar gnutls libgcrypt-devel \
    && yum install -y http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/libtool-ltdl-devel-2.4.6-25.el8.ppc64le.rpm \
    && cd $SOURCE_DIR \
    && git clone https://github.com/lsh123/xmlsec.git \
    && cd xmlsec && git checkout xmlsec-$PACKAGE_VERSION \
    && ./autogen.sh \
    && make \
    && make install \
    && make clean \
    && cd $SOURCE_DIR && rm -rf $SOURCE_DIR/xmlsec

CMD [ "bash" ]
