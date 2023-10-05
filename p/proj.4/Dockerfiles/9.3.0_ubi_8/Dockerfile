FROM registry.access.redhat.com/ubi8/ubi:8.7 as builder

ARG PACKAGE_VERSION=9.3.0
ARG DESTDIR="/build"

# Setup build env
RUN yum install -y git gcc-c++ gcc wget make cmake python38 yum-utils apr-devel perl openssl-devel automake autoconf libtool sqlite-devel libtiff-devel  curl-devel diffutils

RUN git clone https://github.com/OSGeo/proj.4.git \
    && cd proj.4 \
    && git checkout $PACKAGE_VERSION\
    && mkdir build \
    && cd build \
    && cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
    && make -j$(nproc) \
    && make install

FROM registry.access.redhat.com/ubi8/ubi-minimal:8.7

COPY --from=builder  /build/usr/share/proj/ /usr/share/proj/
COPY --from=builder  /build/usr/include/ /usr/include/
COPY --from=builder  /build/usr/bin/ /usr/bin/

