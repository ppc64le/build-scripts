FROM registry.access.redhat.com/ubi8/ubi:8.7 AS build

ENV LUAJIT_VERSION=v2.1-20230911
ENV LUAJIT_PACKAGE_NAME=luajit2
ENV LUAJIT_PACKAGE_URL=https://github.com/openresty/${LUAJIT_PACKAGE_NAME}.git
ENV PATCH_FILE=https://raw.githubusercontent.com/ppc64le/build-scripts/master/l/luajit2/luajit2_${LUAJIT_VERSION}.patch
#ENV PATCH_FILE=https://raw.githubusercontent.com/sumitd2/build-scripts/luajit2/l/luajit2/luajit2_${LUAJIT_VERSION}.patch

#Install required repos
RUN yum install -y dnf && \
    dnf install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm && \
    dnf install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm && \
    dnf config-manager --enable powertools && \
    dnf install -y epel-release

#Install dependencies
RUN yum install -y \
    gcc \
    gcc-c++ \
    make \
    git \
    zip unzip \
    wget \
    pkgconf \
    gtk2-devel \
    libffi-devel \
    sqlite-devel \
    mpfr-devel \
    libmpc-devel \
    ncurses-devel \
    perl \
    gd-devel \
    valgrind-devel

#Download source code and build
RUN cd /tmp && wget ${PATCH_FILE} && git clone ${LUAJIT_PACKAGE_URL} && cd ${LUAJIT_PACKAGE_NAME} && git checkout ${LUAJIT_VERSION} && git apply ../${LUAJIT_PACKAGE_NAME}_${LUAJIT_VERSION}.patch && make -j $(nproc) && make install


FROM registry.access.redhat.com/ubi8/ubi:8.7

RUN groupadd luajit2 && adduser -g luajit2 luajit2

COPY --from=build /usr/local/bin/luajit /bin/luajit2

USER luajit2

#Entry point
ENTRYPOINT ["/bin/luajit2"]

