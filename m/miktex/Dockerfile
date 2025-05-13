FROM registry.access.redhat.com/ubi9/ubi:9.3

ENV SCRIPT_PACKAGE_VERSION=25.4 \
    PACKAGE_NAME=miktex \
    PYTHON_VERSION=3.11.5 \
    CMAKE_VERSION=3.28.1 \
    PACKAGE_URL=https://github.com/MiKTeX/miktex \
    BUILD_HOME=/opt/build \
    PATH=/usr/local/cmake/bin:$PATH

WORKDIR ${BUILD_HOME}

# Install required tools and dependencies
RUN yum install -y \
    git wget gcc gcc-c++ diffutils gettext libxslt make \
    openssl-devel bzip2-devel libffi-devel xz zlib-devel \
    openblas-devel dnf-plugins-core && \
    \
    # Import GPG keys
    wget http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-Official && \
    mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/ && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official && \
    \
    # Add CentOS Repos
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/ && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/ && \
    dnf config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/

# Install Python from source
RUN wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz && \
    tar xzf Python-${PYTHON_VERSION}.tgz && rm -f Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION} && \
    ./configure --with-system-ffi --with-computed-gotos --enable-loadable-sqlite-extensions && \
    make -j$(nproc) && \
    make altinstall && \
    ln -sf $(which python3.11) /usr/bin/python3 && \
    ln -sf $(which pip3.11) /usr/bin/pip3

# Install CMake from source
RUN wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
    tar -zxvf cmake-${CMAKE_VERSION}.tar.gz && rm -f cmake-${CMAKE_VERSION}.tar.gz && \
    cd cmake-${CMAKE_VERSION} && \
    ./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_USE_OPENSSL=ON && \
    make install -j$(nproc)

# Install dependencies
RUN yum install -y \
    https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/bison-3.7.4-5.el9.ppc64le.rpm \
    https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/flex-2.6.4-9.el9.ppc64le.rpm \
    && \
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

# Clone MiKTeX and checkout specific version
RUN git clone ${PACKAGE_URL} && \
    cd miktex && \
    git checkout ${SCRIPT_PACKAGE_VERSION}

# apply patch file
RUN cd miktex && git apply --reject --whitespace=fix --ignore-space-change --ignore-whitespace ../miktex_v25.4.patch

# Build and test
RUN cd miktex && \
    cmake . && \
    make && \
    make test

CMD ["bash"]
