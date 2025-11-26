FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Aastha Sharma <aastha.sharma4@ibm.com>"

ARG PACKAGE_VERSION=v12.2.0

RUN yum install -y git gcc-toolset-13 make wget openssl-devel bzip2-devel libffi-devel zlib-devel python3 python3-devel python3-pip

ENV PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH"

RUN wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz && \
    tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz && \
    cd rust-1.75.0-powerpc64le-unknown-linux-gnu && \
    ./install.sh && \
    export PATH=$HOME/.cargo/bin:$PATH && \
    cd ../ 

RUN git clone https://github.com/stripe/stripe-python.git && \
    cd stripe-python && \
    git checkout $PACKAGE_VERSION && \
    cd deps && \
    pip install pip wheel && \
    pip install pytest tox && \
    pip install -r build-requirements.txt && \
    pip install -r test-requirements.txt && \
    cd .. && \
    pip install . 

CMD ["/bin/bash"]
