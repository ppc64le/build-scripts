FROM registry.access.redhat.com/ubi9/ubi:9.6 AS build

ARG APPLYMCPU=0

ENV MILVUS_VERSION=v2.6.5
ENV MILVUS_PACKAGE_NAME=milvus
ENV MILVUS_PACKAGE_URL=https://github.com/milvus-io/${MILVUS_PACKAGE_NAME}.git
ENV CMAKE_VERSION=3.30.5
ENV GO_VERSION=1.24.11

ENV PATH=/usr/local/go/bin:/usr/local/cmake/bin:${PATH}
ENV VCPKG_FORCE_SYSTEM_BINARIES=1
ENV CONAN_CMAKE_PROGRAM=/usr/local/cmake/bin/cmake

# ------------------------------------------------------------
# Install required repos
# ------------------------------------------------------------
RUN rpm -e --nodeps openssl-fips-provider openssl-fips-provider-so || true && \
	yum update -y --nobest --nogpgcheck && \
	dnf swap -y curl-minimal curl && \
	yum install -y yum-utils && \
	yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os && \
	yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os && \
	yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os && \
	dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
	yum clean all && rm -rf /var/cache/yum

# ------------------------------------------------------------
# Build dependencies
# ------------------------------------------------------------
RUN rpm -e --nodeps openssl-fips-provider openssl-fips-provider-so || true && \
	yum update -y --nobest --nogpgcheck && \
	yum install -y --nobest --nogpgcheck \
		make wget git sudo zip unzip tar diffutils pkg-config \
		python3-devel perl-IPC-Cmd perl-Digest-SHA perl-FindBin \
		perl-File-Compare openssl-devel scl-utils openblas-devel \
		rust cargo gcc gcc-c++ libstdc++-static which \
		libaio libuuid-devel ncurses-devel ccache libtool \
		m4 autoconf automake ninja-build zlib-devel libffi-devel \
		gfortran yum-utils patchelf hdf5-devel sqlite-devel \
		bzip2-devel xz-devel perl-open.noarch && \
	yum clean all && rm -rf /var/cache/yum && \
	pip3 install --no-cache-dir conan==1.64.1 setuptools==59.5.0

# ------------------------------------------------------------
# Configure Conan (Profile & Settings)
# ------------------------------------------------------------
RUN conan profile new default --detect --force && \
	conan profile update settings.compiler.libcxx=libstdc++11 default && \
	conan profile update conf.tools.cmake.cmaketoolchain:generator=Unix\ Makefiles default

# ------------------------------------------------------------
# Build and install CMake (SYSTEM CMAKE + CONAN EXPORT)
# ------------------------------------------------------------
WORKDIR /tmp
RUN wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
	tar -xzf cmake-${CMAKE_VERSION}.tar.gz && \
	cd cmake-${CMAKE_VERSION} && \
	./bootstrap --prefix=/usr/local/cmake --parallel=2 \
	  -- -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release && \
	make install -j$(nproc) && \
	mkdir -p /tmp/cmake_pkg && cd /tmp/cmake_pkg && \
	printf 'from conans import ConanFile\nclass CmakeConan(ConanFile):\n  name=\"cmake\"\n  package_type=\"application\"\n  version=\"%s\"\n  settings=\"os\",\"arch\"\n  def package(self): pass\n  def package_info(self): self.cpp_info.bindirs=[\"bin\"]\n' "${CMAKE_VERSION}" > conanfile.py && \
	conan export-pkg . cmake/${CMAKE_VERSION}@ -s os=Linux -s arch=ppc64le

# ------------------------------------------------------------
# Install Go
# ------------------------------------------------------------
WORKDIR /tmp
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
	rm -rf /usr/local/go && \
	tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz

# ------------------------------------------------------------
# Milvus source
# ------------------------------------------------------------
WORKDIR /tmp
# Download patch file.
COPY milvus_v2.6.5.patch .

RUN git clone -b ${MILVUS_VERSION} ${MILVUS_PACKAGE_URL} && \
	cd milvus && \
	git apply ../milvus_v2.6.5.patch && \
	go get github.com/dvsekhvalnov/jose2go@v1.7.0

WORKDIR /tmp/milvus

# ------------------------------------------------------------
# Conan override file
# ------------------------------------------------------------
RUN cat > conanfile.txt <<-EOF
[requires]
fmt/8.1.1

[generators]
cmake
cmake_find_package

[build_requires]
cmake/${CMAKE_VERSION}
EOF

RUN mkdir -p /root/.cargo/bin

# ------------------------------------------------------------
# Build Environment Variables
# ------------------------------------------------------------
ENV MILVUS_JEMALLOC_BUILD_VERSION=5.3.0
ENV JEMALLOC_CONF="--disable-prof"
ENV JEMALLOC_CONFIGURE_FLAGS="--disable-prof"
ENV LD_LIBRARY_PATH="/tmp/milvus/lib"
ENV CXXFLAGS="-Wno-psabi -Wno-error -Wno-deprecated-declarations -Wno-unused-result"
ENV CFLAGS="-Wno-psabi -Wno-error -Wno-deprecated-declarations -Wno-unused-result"

RUN sed -i 's/export CXXFLAGS="-Wno-error=address -Wno-error=deprecated-declarations"/export CXXFLAGS="-Wno-error=address -Wno-error=deprecated-declarations -Wno-unused-result -Wno-psabi -Wno-error"/g' scripts/3rdparty_build.sh && \
	sed -i 's/export CFLAGS="-Wno-error=address -Wno-error=deprecated-declarations"/export CFLAGS="-Wno-error=address -Wno-error=deprecated-declarations -Wno-unused-result -Wno-psabi -Wno-error"/g' scripts/3rdparty_build.sh && \
	sed -i 's/+1.89//g' internal/core/thirdparty/tantivy/CMakeLists.txt

RUN make -j8 && \
	# Remove example/test keys to prevent security leaks in final image 
    # Reported in CVE as HIGH Severity
	rm -rf /tmp/milvus/configs/cert/*.key /tmp/milvus/configs/cert/*.pem

# ============================================================
# Runtime image
# ============================================================
FROM registry.access.redhat.com/ubi9/ubi:9.6

RUN rpm -e --nodeps openssl-fips-provider openssl-fips-provider-so || true && \
	yum update -y --nobest --nogpgcheck && \
	yum swap -y curl-minimal curl && \
	yum install -y libatomic openblas-devel && \
	yum clean all && rm -rf /var/cache/yum

COPY --from=build /tmp/milvus/bin/ /milvus/bin/
COPY --from=build /tmp/milvus/configs/ /milvus/configs/
COPY --from=build /tmp/milvus/internal/core/output/lib64/ /milvus/lib/
COPY --from=build /tmp/milvus/internal/core/output/lib/* /milvus/lib/

ENV PATH=/milvus/bin:$PATH
ENV LD_LIBRARY_PATH=/milvus/lib:/usr/lib
ENV LD_PRELOAD=/milvus/lib/libjemalloc.so
ENV MALLOC_CONF=background_thread:true

ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-ppc64le /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

WORKDIR /milvus
