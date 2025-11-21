ARG package_version=2.60.1

FROM registry.access.redhat.com/ubi9/ubi:9.6 AS build

ARG package_version

ENV PACKAGE_NAME="docling"
ENV PACKAGE_VERSION=$package_version
ENV PACKAGE_ORG="docling-project"
ENV PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
ENV PYTORCH_VERSION=2.3.0
ENV CMAKE_VERSION=3.28.1
ENV OPENJPEG_VERSION=v2.5.3
ENV PYPDFIUM2_VERSION=35a88d21450eb395e023ca280c9f4c855ec9684d
ENV TORCHVISION_VERSION=v0.16.0
ENV TREE_SITTER_VERSION=v0.23.2
ENV ABSEIL_VERSION=20230802.2
ENV LLVM_CONFIG=/usr/lib64/llvm16/bin/llvm-config
ENV PATCH_FILE=https://raw.githubusercontent.com/ppc64le/build-scripts/master/d/docling/docling-${PACKAGE_VERSION}.patch
ENV PATH=/usr/local/cmake/bin:${PATH}:/usr/local/bin
ENV LD_LIBRARY_PATH=/usr/local/lib64

#Install required repos
RUN yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os && \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os && \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os && \
    rpm --import https://centos.org/keys/RPM-GPG-KEY-CentOS-Official && \
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    rpm -e --nodeps openssl-fips-provider-so-3.0.7-6.el9_5.ppc64le

#Install dependecies
RUN yum install -y git wget gcc gcc-c++ make python3.11-devel python3.11-pip openssl-devel zlib-devel libjpeg-devel ninja-build libicu-devel lcms2-devel glib2-devel freetype-devel gfortran openblas-devel libxml2-devel libxslt-devel ncurses-devel gn libpng-devel libtiff-devel geos-devel tesseract-devel spatialindex-devel rust cargo llvm16-devel ffmpeg-free ffmpeg-free-devel && ln -s /usr/bin/pip3.11 /usr/bin/pip && ln -s /usr/bin/pip3.11 /usr/bin/pip3 && rm -rf /usr/bin/python && ln -s /usr/bin/python3.11 /usr/bin/python && rm -rf /usr/bin/python3 && ln -s /usr/bin/python3.11 /usr/bin/python3

#Install cmake
WORKDIR /tmp
RUN wget -c https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
    tar -zxvf cmake-${CMAKE_VERSION}.tar.gz && \
    rm -rf cmake-${CMAKE_VERSION}.tar.gz && \
    cd cmake-${CMAKE_VERSION} && \
    ./bootstrap --prefix=/usr/local/cmake --parallel=2 -- -DBUILD_TESTING:BOOL=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DCMAKE_USE_OPENSSL:BOOL=ON && \
    make install -j$(nproc) && \
    cmake --version

# ---------------------------
# Build and Install openjpeg
# ---------------------------
WORKDIR /tmp
RUN git clone "https://github.com/uclouvain/openjpeg.git" && \
    cd openjpeg/ && \
    git checkout $OPENJPEG_VERSION && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    make install && \
    ldconfig

#Build and Install pypdfium2
WORKDIR /tmp
RUN git clone "https://github.com/pypdfium2-team/pypdfium2.git" && \
    cd pypdfium2/ && \
    git checkout $PYPDFIUM2_VERSION && \
    python3 ./setupsrc/pypdfium2_setup/build_native.py --compiler gcc && \
    sed -i 's#7191#6996#g' ./setupsrc/pypdfium2_setup/build_native.py && \
    python3 ./setupsrc/pypdfium2_setup/build_native.py --compiler gcc  && \
    PDFIUM_PLATFORM="sourcebuild" pip3 wheel . --verbose && \
    cp *.whl /tmp

#Build and Install pytorch
WORKDIR /tmp
RUN export PYTORCH_VERSION_CPU="${PYTORCH_VERSION}+cpu"  && \
    export PYTORCH_BUILD_VERSION=${PYTORCH_VERSION_CPU} && \
    git clone https://github.com/pytorch/pytorch && \
    cd pytorch && \
    git checkout v$PYTORCH_VERSION && \
    pip install --prefer-binary --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux/ -r requirements.txt && \
    git submodule sync && \
    git submodule update --init --recursive && \
    export PYTORCH_BUILD_NUMBER=1 && \
    python setup.py bdist_wheel && \
    cp dist/*.whl /tmp && \
    pip install --prefer-binary --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux/ dist/*.whl

#Build and Install torchvision
WORKDIR /tmp
RUN git clone https://github.com/pytorch/vision.git && \
    cd vision && \
    git checkout $TORCHVISION_VERSION && \
    # Below patch is needed to exclude the models that come under SWAG license (CC-BY-NC-4.0)
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/t/torchvision/0001-Exclude-source-that-has-commercial-license.patch && \
    git apply ./0001-Exclude-source-that-has-commercial-license.patch && \
    python setup.py bdist_wheel && \
    cp dist/*.whl /tmp

#Install libtree-sitter-devel
WORKDIR /tmp
RUN git clone https://github.com/tree-sitter/tree-sitter-c && \
    cd tree-sitter-c && \
    git checkout $TREE_SITTER_VERSION && \
    mkdir -p /usr/include/tree_sitter/ && \
    cp src/tree_sitter/*.h /usr/include/tree_sitter/

#Install abseil
WORKDIR /tmp
RUN git clone https://github.com/abseil/abseil-cpp && \
    cd abseil-cpp && \
    git checkout $ABSEIL_VERSION && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=ON -DABSL_BUILD_TESTING=OFF .. && \
    make install && \
    ldconfig

#Get source, apply patch and build wheel
WORKDIR /tmp
RUN wget ${PATCH_FILE} && \
RUN git clone "${PACKAGE_URL}" && \
    cd "${PACKAGE_NAME}" && \
    git checkout "v${PACKAGE_VERSION}" && \
    git apply ../${PACKAGE_NAME}_v${PACKAGE_VERSION}.patch && \
    pip install build && \
    python -m build --wheel && \
    cp dist/*.whl /tmp

#Install docling wheel and its dependencies
RUN pip install wheel==0.45.1 hf_xet==1.2.0 huggingface_hub==1.1.4 && \
    pip install --prefer-binary --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux/ \
        tree_sitter_c==0.23.2 tree-sitter-python==0.23.2 "numpy<2.0" tesserocr==2.9.1 openai-whisper==20230117 /tmp/*.whl

#Copy wheels to be installed in the main stage
RUN find /root/.cache/pip/wheels -name '*.whl' -exec cp "{}" /tmp  \;


FROM registry.access.redhat.com/ubi9/ubi:9.6

ENV HF_HOME=/tmp/
ENV TORCH_HOME=/tmp/
ENV OMP_NUM_THREADS=4
ENV GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no"
ENV LD_LIBRARY_PATH=/usr/local/lib64

#Copy files from the build stage
COPY --from=build /tmp/*.whl /tmp
COPY --from=build /tmp/docling/docs/examples/minimal.py /root/minimal.py
COPY --from=build /tmp/openjpeg /tmp/openjpeg/
COPY --from=build /tmp/abseil-cpp /tmp/abseil-cpp/
COPY --from=build /usr/local/cmake /usr/local/cmake/

#Install required repos
RUN yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os && \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os && \
    yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os && \
    rpm --import https://centos.org/keys/RPM-GPG-KEY-CentOS-Official && \
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    rpm -e --nodeps openssl-fips-provider-so-3.0.7-6.el9_5.ppc64le

#Install dependecies
RUN yum install -y --allowerasing python3.11 python3.11-pip python3.11-devel mesa-libGL glib2 curl wget git procps freetype libicu && \
    ln -s /usr/bin/pip3.11 /usr/bin/pip && ln -s /usr/bin/pip3.11 /usr/bin/pip3 && rm -rf /usr/bin/python && \
    ln -s /usr/bin/python3.11 /usr/bin/python && rm -rf /usr/bin/python3 && ln -s /usr/bin/python3.11 /usr/bin/python3

#Install docling wheel and its dependencies
RUN pip install --prefer-binary --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux/ "numpy<2.0" /tmp/*.whl rapidocr

#Install temporary dependencies
RUN yum install -y gcc gcc-c++ make lcms2-devel libtiff-devel zlib-devel libpng-devel openblas-devel spatialindex-devel

#Install openjpeg2
WORKDIR /tmp/openjpeg/build
RUN make install

#Install abseil-cpp
WORKDIR /tmp/abseil-cpp/build
RUN make install

#Download models
WORKDIR /root
RUN docling-tools models download

#Remove temporary dependencies
RUN rm -rf /tmp/openjpeg /tmp/abseil-cpp /usr/local/cmake /tmp/*.whl && \
    yum remove -y --noautoremove gcc gcc-c++ make lcms2-devel libtiff-devel zlib-devel libpng-devel openblas-devel spatialindex-devel

# On container shell:
# > cd /root/
# > python minimal.py

# Running as `docker run -e DOCLING_ARTIFACTS_PATH=/root/.cache/docling/models` will use the
# model weights included in the container image.
