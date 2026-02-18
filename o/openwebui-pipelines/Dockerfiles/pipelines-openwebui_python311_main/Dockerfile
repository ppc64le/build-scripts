# --- STAGE 1: ddtrace Native Builder ---
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS ddtrace-native-builder

LABEL name="open-webui-pipelines" maintainer="Vikash.Singh14@ibm.com"

USER root

ENV PATH="/root/.cargo/bin:${PATH}" \
    CC=clang \
    PIP_NO_CACHE_DIR=1

RUN microdnf update -y && \
    microdnf install -y \
    --enablerepo=ubi-9-baseos-rpms --enablerepo=ubi-9-appstream-rpms \
    python3.11 python3.11-pip python3.11-devel \
    python3-setuptools python3.11-wheel \
    gcc gcc-c++ make git pkg-config \
    libffi-devel openssl-devel \
    clang clang-libs llvm llvm-devel \
    cmake findutils && \
    microdnf clean all && rm -rf /var/cache/* && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    python3.11 -m pip install --no-cache-dir \
    "cmake>=3.24.2,<3.28" cython setuptools-rust "setuptools_scm[toml]>=4" \
    patchelf semantic_version build

WORKDIR /app
COPY patches /patches

RUN python3.11 -m pip install --no-cache-dir \
    "cmake>=3.24.2,<3.28" cython setuptools-rust "setuptools_scm[toml]>=4" \
    patchelf semantic_version build && \
    git clone --depth=1 --branch v25.0.0 https://github.com/DataDog/libdatadog.git /tmp/libdatadog && \
    cd /tmp/libdatadog && \
    git apply /patches/crashtracker_ppc64le.patch && \
    cargo update -p libc --precise 0.2.178 && \
    cargo rustc --lib --release --crate-type staticlib -p libdd-crashtracker && \
    cd /tmp && \
    git clone --depth=1 --branch v4.3.0 https://github.com/DataDog/dd-trace-py.git /tmp/ddtrace && \
    cd /tmp/ddtrace && \
    git apply /patches/ddttrace_4.3.0_ppc64le.patch && \
    cp /tmp/libdatadog/target/release/liblibdd_crashtracker.a src/native/ && \
    cd src/native && \
    cargo build --release --features "pyo3/extension-module profiling" && \
    cd ../.. && \
    mkdir -p /artifacts/ddtrace && \
    mkdir -p /usr/local/lib64/python3.11/site-packages/ddtrace/internal/native && \
    cp /tmp/ddtrace/src/native/target/release/lib_native.so \
       /usr/local/lib64/python3.11/site-packages/ddtrace/internal/native/_native.cpython-311-powerpc64le-linux-gnu.so && \
    cd /tmp/ddtrace && \
    DD_USE_SYSTEM_LIBDATADOG=1 DD_NO_CRASHTRACKER=1 \
    python3.11 setup.py bdist_wheel --dist-dir=/artifacts/ddtrace && \
    rm -rf /tmp/* /root/.cargo /root/.rustup

# --- STAGE 2: Pipelines Python Builder ---
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS pipelines-python-builder

USER root

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_BUILD_ISOLATION=1

WORKDIR /app
COPY patches/requirements.patch /patches/requirements.patch

RUN microdnf update -y && \
    microdnf install -y \
    python3.11 python3.11-pip python3.11-devel python3.11-wheel \
    gcc gcc-c++ make git pkg-config \
    libffi-devel openssl-devel \
    cmake findutils patch && \
    microdnf clean all && rm -rf /var/cache/* && \
    python3.11 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip

COPY --from=ddtrace-native-builder /artifacts/ddtrace/*.whl /tmp/
COPY --from=ddtrace-native-builder \
    /usr/local/lib64/python3.11/site-packages/ddtrace/internal/native/_native.cpython-311-powerpc64le-linux-gnu.so \
    /opt/venv/lib/python3.11/site-packages/ddtrace/internal/native/

RUN mkdir -p /opt/venv/lib/python3.11/site-packages/ddtrace/internal/native && \
    /opt/venv/bin/pip install /tmp/ddtrace-*.whl && \
    rm -rf /tmp/* && \
    git clone --depth=1 https://github.com/open-webui/pipelines.git . && \
    patch -p1 < /patches/requirements.patch && \
    /opt/venv/bin/pip install \
    --no-cache-dir --prefer-binary --only-binary=all \
    --index-url https://pypi.org/simple \
    --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux \
    "grpcio==1.71.0" \
    "opencv-python==4.10.0.84" \
    -r requirements.txt && \
    rm -rf ~/.cache .git

ENV PATH="/opt/venv/bin:${PATH}"

RUN find /opt/venv -name '__pycache__' -type d -prune -exec rm -rf {} + && \
    find /opt/venv -type f -name '*.a' -delete && \
    find /opt/venv -type d -name 'doc' -o -name 'docs' -o -name 'tests' -o -name '*.egg-info' | xargs rm -rf 2>/dev/null || true

# --- STAGE 3: Runtime ---
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS pipelines-runtime

USER root
WORKDIR /app

ENV ENV=prod \
    PORT=9099 \
    HOST=0.0.0.0 \
    DD_AGENT_HOST=host.dockerinternal \
    DD_TRACE_AGENT_PORT=8126 \
    DD_PROFILING_ENABLED=true \
    PYTHONPATH=/app \
    PATH="/opt/venv/bin:${PATH}"

RUN microdnf update -y && \
    microdnf install -y python3.11 bash findutils && \
    microdnf clean all && rm -rf /var/cache/*

COPY --from=pipelines-python-builder /app /app
COPY --from=pipelines-python-builder /opt/venv /opt/venv

RUN mkdir -p /.cache /.local && \
    chgrp -R 0 /app /.cache /.local /opt/venv 2>/dev/null || true && \
    chmod -R g+rwX /app /.cache /.local /opt/venv 2>/dev/null || true && \
    find /app /opt/venv -type d -exec chmod g+s {} + 2>/dev/null || true

EXPOSE ${PORT}
ENTRYPOINT ["bash", "start.sh"]