FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Aastha Sharma <aastha.sharma4@ibm.com>"

ARG PACKAGE_VERSION=v3.6.0

RUN yum install -y  --allowerasing python3 python3-devel python3-pip git wget curl make bzip2 bzip2-devel openssl openssl-devel gcc-toolset-13 && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y && \
    PATH="$HOME/.cargo/bin:$PATH" && \
    source $HOME/.cargo/env && \
    rustc --version
	
ENV PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH"

RUN git clone https://github.com/spotify/luigi.git && \
    cd luigi/ && \
    git checkout $PACKAGE_VERSION && \
    pip3 install deps

RUN pip3 install --upgrade pip && \
    pip3 install \
        'tox<4.0' pytest pytest-cov pyhive mypy codecov \
        types-toml types-requests types-python-dateutil \
        psutil mock selenium hypothesis jsonschema boto3 avro \
        "prometheus-client>=0.5,<0.15" \
        azure-storage-blob==2.1.0 azure-mgmt-resource \
        azure-storage==0.36.0 "elasticsearch<7.14" \
        "moto[all]==4.2.9" requests-unixsocket "sqlalchemy<2" datadog


RUN cd luigi && pip3 install -e ".[toml]"

ENV AWS_REGION=us-east-1
ENV AWS_DEFAULT_REGION=us-east-1

CMD ["/bin/bash"]
