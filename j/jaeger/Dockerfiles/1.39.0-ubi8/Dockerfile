FROM registry.access.redhat.com/ubi8/ubi:8.5 as build

ARG GO_VERSION=1.19
ARG JAEGER_VERSION=v1.39.0

ENV GOBUILD "go build -ldflags '-linkmode=external' -trimpath"

RUN yum -y install wget sudo jq curl git make gcc time gnupg2 gcc-c++ python3 && \
    cd /tmp && \
    wget https://golang.org/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -C  /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz

RUN set -eux \
    && git clone --depth=1 --single-branch -b ${JAEGER_VERSION} \
        https://github.com/jaegertracing/jaeger.git \
        /go/src/github.com/jaegertracing/jaeger \
    && cd /go/src/github.com/jaegertracing/jaeger \
    && git submodule update --init --recursive \
    && curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o n \
    && bash n v16.17.1 \
    && curl -o- -L https://yarnpkg.com/install.sh | bash \
    && export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH" \
    && export PATH=$PATH:/usr/local/go/bin \
    && export GOPATH=$HOME/go \
    && export GOOS="$(go env GOOS)" \
    && yarn install --ignore-engines \
    && make install-tools \
    && make build-all-platforms \
    && strip \
        cmd/all-in-one/all-in-one-linux-ppc64le \
        cmd/agent/agent-linux-ppc64le \
        cmd/anonymizer/anonymizer-linux-ppc64le \
        cmd/collector/collector-linux-ppc64le \
        cmd/ingester/ingester-linux-ppc64le \
        cmd/query/query-linux-ppc64le \
        cmd/tracegen/tracegen-linux-ppc64le

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

COPY --from=build /go/src/github.com/jaegertracing/jaeger/cmd/agent/agent-linux-ppc64le /opt/bin/jaeger-agent
COPY --from=build /go/src/github.com/jaegertracing/jaeger/cmd/all-in-one/all-in-one-linux-ppc64le /opt/bin/jaeger
COPY --from=build /go/src/github.com/jaegertracing/jaeger/cmd/anonymizer/anonymizer-linux-ppc64le /opt/bin/anonymizer
COPY --from=build /go/src/github.com/jaegertracing/jaeger/cmd/collector/collector-linux-ppc64le /opt/bin/jaeger-collector
COPY --from=build /go/src/github.com/jaegertracing/jaeger/cmd/ingester/ingester-linux-ppc64le /opt/bin/jaeger-ingester
COPY --from=build /go/src/github.com/jaegertracing/jaeger/cmd/query/query-linux-ppc64le /opt/bin/jaeger-query
COPY --from=build /go/src/github.com/jaegertracing/jaeger/cmd/tracegen/tracegen-linux-ppc64le /opt/bin/tracegen
COPY --from=build /go/src/github.com/jaegertracing/jaeger/jaeger-ui/packages/jaeger-ui/build /opt/jaeger/ui

ENV SPAN_STORAGE_TYPE grpc-plugin
WORKDIR /opt/jaeger

EXPOSE 6831/udp
EXPOSE 6832/udp
EXPOSE 5778
EXPOSE 14268
EXPOSE 14250
EXPOSE 16686

VOLUME ["/tmp"]

CMD ["/opt/bin/jaeger", "--query.static-files", "ui", "--query.ui-config", "jaeger-ui.json", "--collector.http-server.host-port", "--collector.grpc-server.host-port", "--http-server.host-port", "--query.grpc-server.host-port"]
