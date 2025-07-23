FROM ubuntu:bionic

ARG TARGET_DEBIAN_ARCH
ARG TARGET_GNU_ARCH

ENV TARGET_DEBIAN_ARCH=${TARGET_DEBIAN_ARCH:-ppc64el}
ENV TARGET_GNU_ARCH=${TARGET_GNU_ARCH:-powerpc64le}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        curl \
        g++ \
        gcc \
        git \
        libssl-dev \
        make \
        wget \
        bison \
        flex \
        libexpat1-dev \
        libgmp-dev \
        libncurses5-dev \
        libpython3-dev \
        python3 \
        python3-distutils \
        texinfo \
        locales \
        sudo

RUN curl -L https://github.com/Kitware/CMake/releases/download/v3.28.0/cmake-3.28.0.tar.gz | tar -xz && \
    cd cmake-3.28.0 && ./bootstrap --parallel="$(nproc)" && make -j"$(nproc)" install DESTDIR=/cmake
ENV PATH=/cmake/usr/local/bin:$PATH

RUN mkdir /go && \
    curl -L https://go.dev/dl/go1.18.3.linux-"$(dpkg --print-architecture)".tar.gz | tar -xz -C /go
ENV PATH=/go:$PATH

RUN git clone --branch=section-map-20220801 --depth=1 https://github.com/iii-i/binutils-gdb.git && \
    cd binutils-gdb && ./configure --with-python=python3 && make -j"$(nproc)" && make -j"$(nproc)" install DESTDIR=/gdb

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -

RUN apt install --yes software-properties-common && \
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    add-apt-repository "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic-16 main" && \
    apt update && \
    apt install --yes clang-16 llvm-16 && \
    ln -s /usr/bin/clang-16 /usr/bin/clang && \
    ln -s /usr/bin/clang++-16 /usr/bin/clang++

COPY sources.list /etc/apt/.

RUN dpkg --add-architecture "$TARGET_DEBIAN_ARCH" && \
    apt-get update && \
    apt-get install --no-install-recommends --yes \
        binutils-multiarch \
        crossbuild-essential-"$TARGET_DEBIAN_ARCH" \
        gawk \
        git \
        jq \
        less \
        libgcc-8-dev-"$TARGET_DEBIAN_ARCH"-cross \
        libicu-dev:"$TARGET_DEBIAN_ARCH" \
        libkrb5-dev:"$TARGET_DEBIAN_ARCH" \
        liblttng-ust-dev:"$TARGET_DEBIAN_ARCH" \
        liblttng-ust0 \
        libssl-dev:"$TARGET_DEBIAN_ARCH" \
        libstdc++-8-dev-"$TARGET_DEBIAN_ARCH"-cross \
        libxml2-utils \
        locales \
        lttng-modules-dkms \
        lttng-tools \
        mono-devel \
        ninja-build \
        nodejs \
        psmisc \
        quilt \
        ssh \
        strace \
        tmux \
        unzip \
        vim \
        yarn \
        zlib1g-dev:"$TARGET_DEBIAN_ARCH" \
        zsh

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

ENV CROSSCOMPILE=1 \
    ROOTFS_DIR=/ \
    PKG_CONFIG_PATH=/usr/lib/$TARGET_GNU_ARCH-linux-gnu/pkgconfig
