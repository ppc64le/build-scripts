# Build Stage
FROM registry.access.redhat.com/ubi9/ubi:9.3 as builder

ENV SCRIPT_PACKAGE_VERSION=25.4 \
    PACKAGE_NAME=miktex \
    PYTHON_VERSION=3.11.5 \
    CMAKE_VERSION=3.28.1 \
    PACKAGE_URL=https://github.com/MiKTeX/miktex \
    BUILD_HOME=/opt/build \
    PATH=/usr/local/cmake/bin:$PATH

ENV PATCH_FILE=https://raw.githubusercontent.com/ppc64le/build-scripts/master/m/miktex/miktex_v${SCRIPT_PACKAGE_VERSION}.patch
#ENV PATCH_FILE=https://raw.githubusercontent.com/Simran-Sirsat/build-scripts/miktex/m/miktex/miktex_v${SCRIPT_PACKAGE_VERSION}.patch

WORKDIR ${BUILD_HOME}

# Install build dependencies
RUN yum install -y \
    git wget gcc gcc-c++ diffutils gettext libxslt make \
    openssl-devel bzip2-devel libffi-devel xz zlib-devel \
    openblas-devel dnf-plugins-core gnupg rpm-build && \
    \
    # Import GPG keys
    wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official && \
    mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/ && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official && \
    \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/ && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/ && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/

# Install Python from source
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar xzf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions && \
    make -j$(nproc) && make altinstall && \
    ln -sf $(which python3.11) /usr/bin/python3 && ln -sf $(which pip3.11) /usr/bin/pip3

# Install CMake from source
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
    tar -zxvf cmake-${CMAKE_VERSION}.tar.gz && \
    cd cmake-${CMAKE_VERSION} && \
    ./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_USE_OPENSSL=ON && \
    make install -j$(nproc)

# Install MiKTeX build dependencies
RUN yum install -y \
    https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/bison-3.7.4-5.el9.ppc64le.rpm \
    https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/flex-2.6.4-9.el9.ppc64le.rpm && \
    dnf install --nodocs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    yum install -y apr-devel apr-util-devel boost-devel bzip2-devel cairo-devel curl-devel \
    fribidi-devel gd-devel gmp-devel hunspell-devel log4cxx log4cxx-devel \
    uriparser uriparser-devel zziplib-devel cups-devel libmspack libmspack-devel \
    popt popt-devel mpfr-devel autoconf automake libtool \
    https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qt3d-6.6.2-1.el9.ppc64le.rpm \
    https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qt5compat-devel-6.6.2-1.el9.ppc64le.rpm \
    https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qt3d-devel-6.6.2-1.el9.ppc64le.rpm \
    https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qttools-devel-6.6.2-2.el9.ppc64le.rpm

# Build and install MPFI from source
RUN git clone https://gitlab.inria.fr/mpfi/mpfi.git && \
    cd mpfi && autoreconf -v -i && ./autogen.sh && ./configure && make && make install

# Install Gosu from source
RUN \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.14/gosu-ppc64el"; \
    curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.14/gosu-ppc64el.asc"; \
    gpg --batch --verify /usr/local/bin/gosu.asc; \
    rm /usr/local/bin/gosu.asc; \
    chmod +x /usr/local/bin/gosu

COPY miktex_v25.4.patch ${BUILD_HOME}/miktex_v25.4.patch

# Clone and patch MiKTeX
RUN git clone ${PACKAGE_URL} \
    && cd miktex && git checkout ${SCRIPT_PACKAGE_VERSION} \
    && wget ${PATCH_FILE} \
    && git apply --reject --whitespace=fix --ignore-space-change --ignore-whitespace miktex_v${SCRIPT_PACKAGE_VERSION}.patch

# Build MiKTeX
RUN cd miktex && \
    cmake . && \
    make && \
    make package && \
    make test

# Final Stage
FROM registry.access.redhat.com/ubi9/ubi:9.3
ARG user=miktex
ARG group=miktex
ARG uid=1000
ARG gid=1000
ARG miktex_home=/var/lib/miktex
ARG miktex_work=/miktex/work
RUN groupadd -g ${gid} ${group} \
    && useradd -d "${miktex_home}" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

#Install centos and epel repos
RUN yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
RUN yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
RUN yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
RUN rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Install MiKTeX runtime dependencies
RUN yum install -y \
    gd log4cxx boost libmspack zziplib uriparser harfbuzz-icu hunspell \
    https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qt3d-6.6.2-1.el9.ppc64le.rpm \
    https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qt5compat-6.6.2-1.el9.ppc64le.rpm \
    https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qt3d-6.6.2-1.el9.ppc64le.rpm \
    https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/q/qt6-qttools-6.6.2-2.el9.ppc64le.rpm

# Copy required binaries from builder
COPY --from=builder /opt/build/miktex/miktex-25.4-1.ppc64le.rpm /tmp
COPY --from=builder /usr/local/lib/libmpfi.so.0 /usr/lib/libmpfi.so.0
COPY --from=builder /usr/local/lib/libmpfi.so /usr/lib/libmpfi.so
RUN ldconfig

# Install miktex from the newly built rpm
RUN rpm -i --nodeps /tmp/miktex-25.4-1.ppc64le.rpm
RUN rm -rf /tmp/miktex-25.4-1.ppc64le.rpm
RUN initexmf --set-config-value=[MPM]AutoInstall=1 \
    && miktex packages update \
    && miktex packages install amsfonts

# Install Gosu from source
RUN \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.14/gosu-ppc64el"; \
    curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.14/gosu-ppc64el.asc"; \
    gpg --batch --verify /usr/local/bin/gosu.asc; \
    rm /usr/local/bin/gosu.asc; \
    chmod +x /usr/local/bin/gosu

# Download entrypoint
RUN curl -o /entrypoint.sh https://raw.githubusercontent.com/MiKTeX/docker-miktex/03813a57971014feba86885f939e9e69998fa9ac/entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch user
USER ${user}
VOLUME [ "${miktex_home}" ]
WORKDIR ${miktex_work}
USER root

# Specify entrypoint
ENTRYPOINT ["/entrypoint.sh"]
ENV PATH=/var/lib/miktex/bin:${PATH}
CMD ["bash"]
