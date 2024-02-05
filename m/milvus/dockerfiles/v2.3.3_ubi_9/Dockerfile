FROM registry.access.redhat.com/ubi9/ubi:9.3 AS build

ARG APPLYMCPU=0

ENV MILVUS_VERSION=v2.3.3
ENV MILVUS_PACKAGE_NAME=milvus
ENV MILVUS_PACKAGE_URL=https://github.com/milvus-io/${MILVUS_PACKAGE_NAME}.git
ENV CMAKE_VERSION=3.28.1
ENV GO_VERSION=1.21.4

ENV PATCH_FILE=https://raw.githubusercontent.com/ppc64le/build-scripts/master/m/milvus/milvus-${MILVUS_VERSION}.patch
ENV PATH=${HOME}/go/bin:/usr/local/go/bin:/usr/local/cmake/bin:/opt/at16.0/bin:${PATH}
ENV VCPKG_FORCE_SYSTEM_BINARIES=1

#Install IBM Advanced Toolchain repo
RUN yum install -y wget && \
    wget https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL9/gpg-pubkey-615d762f-62f504a1 && \
    rpm --import gpg-pubkey-615d762f-62f504a1 && \
    touch /etc/yum.repos.d/advance-toolchain.repo && \
    printf '[advance-toolchain] \n\
name=Advance Toolchain IBM FTP \n\
baseurl=https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL9 \n\
enabled=1 \n\
gpgcheck=1 \n\
gpgkey=https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL9/gpg-pubkey-615d762f-62f504a1' >>  /etc/yum.repos.d/advance-toolchain.repo

#Install required repos
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

#Install dependencies
RUN yum install -y --allowerasing make wget git sudo curl zip unzip tar diffutils pkg-config python3-devel perl-IPC-Cmd perl-Digest-SHA perl-FindBin perl-File-Compare openssl-devel scl-utils advance-toolchain-at16.0-runtime advance-toolchain-at16.0-devel advance-toolchain-at16.0-perf which libaio libuuid-devel ncurses-devel ccache libtool m4 autoconf automake ninja-build rust && \
    rm -rf /opt/at16.0/bin/pip3 /opt/at16.0/bin/python3 && \
    pip3 install conan==1.61.0

#Install cmake
WORKDIR /tmp
RUN  wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
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
RUN yum remove -y gcc gcc-c++ && \
    yum install -y libxcrypt-devel && \
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
    sed -i 's#"12.3"#"12.3", "12.3.1"#g' $HOME/.conan/settings.yml && \
    go mod tidy && \
    make -j$(nproc)



FROM registry.access.redhat.com/ubi9/ubi:9.3

#Install IBM Advanced Toolchain repo
RUN yum install -y wget && \
    wget https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL9/gpg-pubkey-615d762f-62f504a1 && \
    rpm --import gpg-pubkey-615d762f-62f504a1 && \
    touch /etc/yum.repos.d/advance-toolchain.repo && \
    printf '[advance-toolchain] \n\
name=Advance Toolchain IBM FTP \n\
baseurl=https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL9 \n\
enabled=1 \n\
gpgcheck=1 \n\
gpgkey=https://public.dhe.ibm.com/software/server/POWER/Linux/toolchain/at/redhat/RHEL9/gpg-pubkey-615d762f-62f504a1' >>  /etc/yum.repos.d/advance-toolchain.repo

#Install required repos
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

RUN dnf install -y --allowerasing curl ca-certificates libgomp libatomic advance-toolchain-at16.0-runtime advance-toolchain-at16.0-devel advance-toolchain-at16.0-perf && \
    dnf install -y https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/libaio-devel-0.3.111-13.el9.ppc64le.rpm 

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
