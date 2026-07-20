# -----------------------------------------------------------------------------
# Builder Stage
# -----------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/ubi:9.7 AS builder

LABEL stage=builder

# Install build dependencies
RUN dnf upgrade -y --allowerasing && \
    dnf install -y \
        git \
        wget \
        tar \
        make \
        gcc \
        gcc-c++ && \
    dnf clean all && \
    rm -rf /var/cache/dnf

# -----------------------------------------------------------------------------
# Go 1.26.3
# -----------------------------------------------------------------------------
ENV GO_VERSION=1.26.3 \
    GOPATH=/go \
    PATH=/usr/local/go/bin:/go/bin:$PATH \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=ppc64le

RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    rm -f go${GO_VERSION}.linux-ppc64le.tar.gz && \
    go version

WORKDIR /workspace

# -----------------------------------------------------------------------------
# Build Grafana Operator
# -----------------------------------------------------------------------------
ARG GRAFANA_OPERATOR_VERSION=v5.22.2

RUN git clone --branch ${GRAFANA_OPERATOR_VERSION} --depth 1 \
    https://github.com/grafana/grafana-operator.git . && \
    go mod download && \
    make build && \
    cp bin/manager /workspace/grafana-operator

# -----------------------------------------------------------------------------
# Build OpenTelemetry Collector from source
# -----------------------------------------------------------------------------
ARG OTEL_COLLECTOR_VERSION=0.136.0

RUN git clone https://github.com/open-telemetry/opentelemetry-collector.git \
      /tmp/opentelemetry-collector && \
    cd /tmp/opentelemetry-collector && \
    git checkout v${OTEL_COLLECTOR_VERSION} && \
    cd cmd/otelcorecol && \
    go get google.golang.org/grpc@v1.79.3 && \
    go get go.opentelemetry.io/otel@v1.43.0 && \
    go get go.opentelemetry.io/otel/sdk@v1.43.0 && \
    go mod tidy && \
    go build -v -trimpath -o /workspace/otelcol . && \
    chmod +x /workspace/otelcol && \
    /workspace/otelcol --version && \
    rm -rf /tmp/opentelemetry-collector

# -----------------------------------------------------------------------------
# Runtime Stage
# -----------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

LABEL maintainer="Amit Kumar <amit.kumar282@ibm.com>" \
      version="5.22.2" \
      description="Grafana Operator with OpenTelemetry support for ppc64le" \
      architecture="ppc64le"

# -----------------------------------------------------------------------------
# System packages
# -----------------------------------------------------------------------------
RUN microdnf upgrade -y && \
    microdnf install -y \
        ca-certificates \
        tzdata \
        shadow-utils \
        tar \
        gzip \
        findutils \
        procps-ng && \
    microdnf update -y gnutls krb5-libs && \
    microdnf clean all && \
    rm -rf /var/cache/yum

ENV PATH=/usr/local/bin:$PATH

# -----------------------------------------------------------------------------
# Copy rebuilt binaries
# -----------------------------------------------------------------------------
COPY --from=builder /workspace/grafana-operator \
    /usr/local/bin/grafana-operator

COPY --from=builder /workspace/otelcol \
    /usr/local/bin/otelcol

RUN chmod +x /usr/local/bin/grafana-operator && \
    chmod +x /usr/local/bin/otelcol

# -----------------------------------------------------------------------------
# Required directories
# -----------------------------------------------------------------------------
RUN mkdir -p \
      /etc/grafana-operator \
      /etc/otel-collector \
      /var/log/grafana-operator \
      /var/lib/grafana-operator

# -----------------------------------------------------------------------------
# OpenTelemetry Configuration
# -----------------------------------------------------------------------------
RUN cat > /etc/otel-collector/config.yaml <<'EOF'
receivers:
  otlp:
    protocols:
      grpc:
      http:

processors:
  batch:
  memory_limiter:
    limit_mib: 512
    check_interval: 1s

exporters:
  logging:
    loglevel: info

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [logging]

    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [logging]

    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [logging]
EOF

# -----------------------------------------------------------------------------
# Startup Script
# -----------------------------------------------------------------------------
RUN cat > /usr/local/bin/start-operator.sh <<'EOF'
#!/bin/sh
set -e

cleanup() {
  [ -n "${OTEL_PID}" ] && kill "${OTEL_PID}" 2>/dev/null || true
}

trap cleanup TERM INT

if [ "${ENABLE_OTEL}" = "true" ]; then
  echo "Starting OpenTelemetry Collector..."
  /usr/local/bin/otelcol \
    --config=/etc/otel-collector/config.yaml &
  OTEL_PID=$!
fi

exec /usr/local/bin/grafana-operator "$@"
EOF

RUN chmod +x /usr/local/bin/start-operator.sh

# -----------------------------------------------------------------------------
# Non-root user
# -----------------------------------------------------------------------------
RUN useradd -r -u 65532 -g 0 -s /sbin/nologin \
    -c "Grafana Operator User" grafana-operator && \
    chown -R 65532:0 \
      /etc/grafana-operator \
      /etc/otel-collector \
      /var/log/grafana-operator \
      /var/lib/grafana-operator && \
    chmod -R g=u \
      /etc/grafana-operator \
      /etc/otel-collector \
      /var/log/grafana-operator \
      /var/lib/grafana-operator

USER 65532:0
WORKDIR /var/lib/grafana-operator

EXPOSE 8080 8081 4317 4318

ENV ENABLE_OTEL=true \
    OTEL_SERVICE_NAME=grafana-operator

ENTRYPOINT ["/usr/local/bin/start-operator.sh"]
CMD ["--health-probe-bind-address=:8081", "--metrics-bind-address=:8080"]
