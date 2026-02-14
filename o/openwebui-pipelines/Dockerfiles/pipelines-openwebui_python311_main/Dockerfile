# --- STAGE 1: Build environment ---
FROM registry.access.redhat.com/ubi9/python-311:latest AS builder

LABEL name="openwebui-pipelines" maintainer="Vikash.Singh14@ibm.com"

USER root
WORKDIR /app

RUN dnf update -y && dnf install -y --nodocs \
    gcc gcc-c++ make pkg-config git wget unzip \
    && dnf clean all && rm -rf /var/cache/dnf/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --upgrade pip setuptools wheel

RUN git clone --depth 1 https://github.com/open-webui/pipelines.git /app && \
    rm -rf /app/.git && \
    find /app -name '*.pyc' -o -name '*.pyo' -o -name '__pycache__' -type f -delete

COPY requirements.txt /app/requirements.txt

RUN . /opt/venv/bin/activate && \
    pip install -r requirements.txt \
    --index-url https://pypi.org/simple \
    --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux \
    --prefer-binary --use-deprecated=legacy-resolver --no-cache-dir && \
    rm -rf /root/.cache/pip

# Optional cleanup: remove build tools from builder too
RUN yum remove -y gcc gcc-c++ make pkg-config git \
    && yum autoremove -y \
    && yum clean all \
    && rm -rf /var/cache/yum


# --- STAGE 2: Runtime ---
FROM registry.access.redhat.com/ubi9/python-311:latest

LABEL name="open-webui-pipelines" maintainer="Vikash.Singh14@ibm.com"

USER root
WORKDIR /app

# Copy only what we need from builder
COPY --from=builder --chown=1001:0 /opt/venv /opt/venv
COPY --from=builder --chown=1001:0 /app /app

# Use venv
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Remove build tools that are not needed at runtime
RUN yum remove -y gcc gcc-c++ make pkg-config git \
    && yum autoremove -y \
    && yum clean all \
    && rm -rf /var/cache/yum

# Fix permissions
RUN chmod -R g+rwX /app /opt/venv && \
    find /app -type d -exec chmod g+s {} + 2>/dev/null || true

EXPOSE 9099
USER 1001
CMD ["sh", "-c", "/opt/venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 9099"]