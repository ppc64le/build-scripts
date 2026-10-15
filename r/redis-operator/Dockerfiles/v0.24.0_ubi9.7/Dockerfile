FROM registry.access.redhat.com/ubi9/ubi-minimal:9.7 AS builder
 
ARG GO_VERSION=1.26.2
ARG TARGETOS
ARG TARGETARCH
ARG REDIS_OPERATOR_VERSION=v0.24.0
 
WORKDIR /workspace
 
# Install dependencies
RUN microdnf install -y \
    wget \
    tar \
    gzip \
    git \
&& microdnf clean all
 
# Install Go
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz && \
    tar -C /usr/local -xf go${GO_VERSION}.linux-${TARGETARCH}.tar.gz && \
    rm -f go${GO_VERSION}.linux-${TARGETARCH}.tar.gz
 
# Set Go environment
ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go
ENV PATH=$GOPATH/bin:$GOROOT/bin:$PATH
 
# Clone the repo and checkout version
RUN git clone https://github.com/OT-CONTAINER-KIT/redis-operator.git
WORKDIR /workspace/redis-operator
RUN git checkout $REDIS_OPERATOR_VERSION
 
# Download dependencies
# Fix CVE-2026-35469 by upgrading spdystream
RUN go mod edit -require=github.com/moby/spdystream@v0.5.1 && \
    go mod download github.com/moby/spdystream && \
    go mod download
 
# Build settings
ARG LDFLAGS="-s -w"
 
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH
ENV CGO_ENABLED=0
 
# Build binary
RUN GO111MODULE=on go build -ldflags "${LDFLAGS}" -a -o operator cmd/main.go
 
# Runtime stage
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.7
 
WORKDIR /
 
COPY --from=builder /workspace/redis-operator/operator /operator
 
USER 1001
 
ENTRYPOINT ["/operator", "manager"]
