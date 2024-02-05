FROM registry.access.redhat.com/ubi8/ubi:8.7 AS build

ARG APPLYMCPU=0

ENV MILVUS_VERSION=v2.3.3
ENV MILVUS_PACKAGE_NAME=milvus
ENV MILVUS_PACKAGE_URL=https://github.com/milvus-io/${MILVUS_PACKAGE_NAME}.git
ENV CMAKE_VERSION=3.28.1
ENV GO_VERSION=1.21.4

ENV PATCH_FILE=https://raw.githubusercontent.com/ppc64le/build-scripts/master/m/milvus/milvus-${MILVUS_VERSION}.patch
ENV PATH=${HOME}/go/bin:/usr/local/go/bin:/usr/local/cmake/bin:${PATH}
ENV VCPKG_FORCE_SYSTEM_BINARIES=1

#Install required repos
RUN yum install -y dnf && \
    dnf install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm && \
    dnf install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm && \
    dnf config-manager --enable powertools && \
    dnf install -y epel-release

#Install dependencies
RUN yum install -y make wget git sudo curl zip unzip tar pkg-config python39-devel perl-IPC-Cmd perl-Digest-SHA openssl-devel scl-utils gcc-toolset-11-toolchain gcc-toolset-11-libatomic-devel which libaio libuuid-devel ncurses-devel ccache lcov libtool m4 autoconf automake ninja-build rust libxslt && \
    pip3 install conan==1.61.0

#Install cmake
WORKDIR /tmp
RUN source scl_source enable gcc-toolset-11 && \
    wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
    tar -zxvf cmake-${CMAKE_VERSION}.tar.gz && \
    rm -rf cmake-${CMAKE_VERSION}.tar.gz && \
    cd cmake-${CMAKE_VERSION} && \
    ./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING:BOOL=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_USE_OPENSSL:BOOL=ON && \
    make install -j$(nproc) && \
    cmake --version

#Install Golang
WORKDIR /tmp
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm -rf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    go version

#Get milvus source and apply patch
WORKDIR /tmp
RUN wget ${PATCH_FILE} && \
    git clone -b ${MILVUS_VERSION} ${MILVUS_PACKAGE_URL} && \
    cd ${MILVUS_PACKAGE_NAME} && \
    git apply ../milvus-${MILVUS_VERSION}.patch && \
    if [[ "${APPLYMCPU}" -eq 1 ]]; then sed -i "49d" ./internal/core/CMakeLists.txt; sed -i '49i set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -mcpu=power10")' ./internal/core/CMakeLists.txt; fi

#Build
WORKDIR /tmp/${MILVUS_PACKAGE_NAME}
RUN source scl_source enable gcc-toolset-11 && \
    pushd /usr/local/cmake && \
    touch /usr/local/cmake/conanfile.py && \
    printf 'from conans import ConanFile, tools \n\
class CmakeConan(ConanFile): \n\
  name = "cmake" \n\
  package_type = "application" \n\
  version = '\""${CMAKE_VERSION}\""' \n\
  description = "CMake, the cross-platform, open-source build system." \n\
  homepage = "https://github.com/Kitware/CMake" \n\
  license = "BSD-3-Clause" \n\
  topics = ("build", "installer") \n\
  settings = "os", "arch" \n\
  def package(self): \n\
    self.copy("*") \n\
  def package_info(self): \n\
    self.cpp_info.libs = tools.collect_libs(self)' >> /usr/local/cmake/conanfile.py && \
    conan export-pkg . cmake/${CMAKE_VERSION}@ -s os="Linux" -s arch="ppc64le" && \
    conan profile update settings.compiler.libcxx=libstdc++11 default && \
    popd && \
    go mod tidy && \
    make -j$(nproc)



FROM registry.access.redhat.com/ubi8/ubi:8.7

#Install required repos
RUN yum install -y dnf && \
    dnf install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm && \
    dnf install -y http://mirror.centos.org/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm && \
    dnf config-manager --enable powertools

RUN yum install -y curl ca-certificates libaio-devel libgomp libatomic

COPY --from=build /tmp/milvus/bin/ /milvus/bin/

COPY --from=build /tmp/milvus/configs/ /milvus/configs/

COPY --from=build /tmp/milvus/internal/core/output/lib64/ /milvus/lib/
COPY --from=build /tmp/milvus/internal/core/output/lib/* /milvus/lib/

ENV PATH=/milvus/bin:$PATH
ENV LD_LIBRARY_PATH=/milvus/lib:$LD_LIBRARY_PATH:/usr/lib
ENV LD_PRELOAD=/milvus/lib/libjemalloc.so
ENV MALLOC_CONF=background_thread:true

# Add Tini
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-ppc64le /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

WORKDIR /milvus/
