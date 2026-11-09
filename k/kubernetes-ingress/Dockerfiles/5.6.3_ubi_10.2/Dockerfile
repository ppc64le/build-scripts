# =============================================================================
# NGINX Ingress Controller — ppc64le (Power10) UBI10
# Version: v5.6.3

# Build command (run from Dockerfiles/5.6.3_ubi_10.2/):
#   docker build \
#     --build-arg IC_VERSION=v5.6.3 \
#     --target local \
#     -t nginx/nginx-ingress-ppc64le:5.6.3-ubi \
#     -f Dockerfile .
# =============================================================================

ARG NGINX_OSS_VERSION=1.31.6
ARG NJS_VERSION=1.0.1
ARG IC_VERSION=v5.6.3
ARG NGINX_OTEL_VERSION=v0.1.2
ARG NGINX_ACME_VERSION=v0.4.1
ARG CARES_VERSION=v1.34.8
ARG NGINX_AGENT_VERSION=v3.12.0

# -----------------------------------------------------------------------------
# Stage 1: nginx-src-builder — compile all components from source
# -----------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi10/ubi-minimal:latest AS nginx-src-builder

ARG NGINX_OSS_VERSION
ARG NJS_VERSION
ARG NGINX_OTEL_VERSION
ARG NGINX_ACME_VERSION
ARG CARES_VERSION
ARG NGINX_AGENT_VERSION
ARG IC_VERSION=v5.6.3

ENV GO_VERSION=1.27.3

RUN microdnf install -y --nodocs \
        gcc make tar gzip perl git wget curl cmake \
        pcre2-devel openssl-devel zlib-devel \
        libxml2-devel libxslt-devel \
        gd-devel libjpeg-turbo-devel libpng-devel \
        libcap \
        rust cargo clang-devel clang-libs llvm-devel pkgconf-pkg-config \
    && microdnf clean all

# Install Go (no ppc64le Go RPM available in UBI10)
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz \
    && rm go${GO_VERSION}.linux-ppc64le.tar.gz

ENV PATH=/usr/local/go/bin:$PATH

# Clone kubernetes-ingress source
RUN git clone \
        --depth 1 \
        --branch ${IC_VERSION} \
        https://github.com/nginx/kubernetes-ingress.git \
        /tmp/kubernetes-ingress


COPY kubernetes-ingress_v5.6.3_dockerfile.patch* /tmp/context-patch/
RUN wget -P /tmp https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/k/kubernetes-ingress/Dockerfiles/5.6.3_ubi_10.2/kubernetes-ingress_v5.6.3_dockerfile.patch \
    || cp /tmp/context-patch/kubernetes-ingress_v5.6.3_dockerfile.patch /tmp/
RUN git -C /tmp/kubernetes-ingress apply /tmp/kubernetes-ingress_v5.6.3_dockerfile.patch

# Build nginx-ingress binary
RUN cd /tmp/kubernetes-ingress \
    && CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le \
       go build -trimpath \
       -ldflags "-s -w \
         -X main.version=${IC_VERSION#v} \
         -X main.telemetryEndpoint=oss.edge.df.f5.com:443" \
       -o /usr/bin/nginx-ingress \
       github.com/nginx/kubernetes-ingress/cmd/nginx-ingress \
    && strip /usr/bin/nginx-ingress

# Download nginx and njs sources
RUN curl -fsSL "https://nginx.org/download/nginx-${NGINX_OSS_VERSION}.tar.gz" \
        -o /tmp/nginx.tar.gz \
    && curl -fsSL "https://github.com/nginx/njs/archive/refs/tags/${NJS_VERSION}.tar.gz" \
        -o /tmp/njs.tar.gz \
    && tar -xzf /tmp/nginx.tar.gz -C /tmp \
    && tar -xzf /tmp/njs.tar.gz   -C /tmp \
    && rm  /tmp/nginx.tar.gz /tmp/njs.tar.gz

# Build nginx + dynamic modules (njs, xslt, image_filter).
# cc-opt uses -mcpu=power10 -mtune=power10 with Red Hat security hardening flags.
RUN cd /tmp/nginx-${NGINX_OSS_VERSION} \
    && ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib64/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-control-api \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_v3_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_json_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_auth_request_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_stub_status_module \
        --with-http_xslt_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_realip_module \
        --with-stream_ssl_preread_module \
        --add-dynamic-module=/tmp/njs-${NJS_VERSION}/nginx \
        --with-cc-opt="-mcpu=power10 -mtune=power10 -O2 -pipe -fPIE \
            -fstack-protector-strong -Wp,-D_FORTIFY_SOURCE=2 \
            -Wp,-D_GLIBCXX_ASSERTIONS -fstack-clash-protection" \
        --with-ld-opt="-Wl,-z,relro -Wl,-z,now -pie" \
    && make -j$(nproc) \
    && make install \
    && mkdir -p /usr/lib64/nginx/modules \
    && cp objs/ngx_http_js_module.so            /usr/lib64/nginx/modules/ \
    && cp objs/ngx_stream_js_module.so          /usr/lib64/nginx/modules/ \
    && cp objs/ngx_http_xslt_filter_module.so   /usr/lib64/nginx/modules/ \
    && cp objs/ngx_http_image_filter_module.so  /usr/lib64/nginx/modules/ \
    && rm -f /etc/nginx/*.default /etc/nginx/fastcgi.conf /etc/nginx/koi-utf /etc/nginx/koi-win /etc/nginx/win-utf \
    && cp /usr/sbin/nginx                       /usr/sbin/nginx-debug \
    && strip /usr/sbin/nginx /usr/sbin/nginx-debug \
    && strip /usr/lib64/nginx/modules/*.so

# Default /etc/nginx/nginx.conf identical to the one shipped by the nginx.org packages (and so by the
# upstream x86_64 image); the source install writes a different stock file.
RUN <<'EOF'
cat > /etc/nginx/nginx.conf <<'CONF'

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
CONF
EOF

# Build c-ares from source (c-ares-devel is not available in UBI10 repos)
RUN cd /tmp \
    && git clone https://github.com/c-ares/c-ares.git \
    && cd c-ares \
    && git checkout ${CARES_VERSION} \
    && mkdir build && cd build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local .. \
    && make -j$(nproc) && make install \
    && rm -rf /tmp/c-ares

# Build ngx_otel_module (OpenTelemetry dynamic module for nginx)
RUN cd /tmp \
    && git clone --recurse-submodules https://github.com/nginxinc/nginx-otel.git \
    && cd /tmp/nginx-otel \
    && git checkout ${NGINX_OTEL_VERSION} \
    && mkdir build && cd build \
    && cmake \
        -DNGX_OTEL_NGINX_BUILD_DIR=/tmp/nginx-${NGINX_OSS_VERSION}/objs \
        -DgRPC_CARES_PROVIDER=package \
        -Dc-ares_DIR=/usr/local/lib64/cmake/c-ares \
        .. \
    && make -j$(nproc) \
    && strip ngx_otel_module.so \
    && cp ngx_otel_module.so /usr/lib64/nginx/modules/ \
    && rm -rf /tmp/nginx-otel

RUN cd /tmp \
    && git clone --depth 1 --branch ${NGINX_ACME_VERSION} https://github.com/nginx/nginx-acme.git \
    && cd /tmp/nginx-acme \
    && NGINX_BUILD_DIR=/tmp/nginx-${NGINX_OSS_VERSION}/objs \
       NGX_ACME_STATE_PREFIX=/var/cache/nginx \
       cargo build --release \
    && cp target/release/libnginx_acme.so /usr/lib64/nginx/modules/ngx_http_acme_module.so \
    && strip /usr/lib64/nginx/modules/ngx_http_acme_module.so \
    && rm -rf /tmp/nginx-acme /root/.cargo

# Build nginx-agent from source. 
RUN git clone \
        --depth 1 \
        --branch ${NGINX_AGENT_VERSION} \
        https://github.com/nginx/agent.git \
        /tmp/nginx-agent \
    && cd /tmp/nginx-agent \
    && make build \
    && strip build/nginx-agent \
    && cp build/nginx-agent /usr/bin/nginx-agent \
    && mkdir -p /etc/nginx-agent \
    && cp nginx-agent.conf /etc/nginx-agent/nginx-agent.conf \
    && rm -rf /tmp/nginx-agent

# Build the njs command line tool (upstream ships /usr/bin/njs in the nginx-module-njs package).
RUN cd /tmp/njs-${NJS_VERSION} \
    && ./configure \
    && make -j$(nproc) njs \
    && cp build/njs /usr/bin/njs \
    && strip /usr/bin/njs

# -----------------------------------------------------------------------------
# Stage 2: ubi — minimal runtime image
# -----------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi10/ubi-minimal:latest AS ubi

ARG IC_VERSION
ARG BUILD_DATE=""
ARG VCS_REF=""

# Labels follow the upstream x86_64 image (build/Dockerfile "common" stage and the build-oss.yml metadata action); 
LABEL name="NGINX Ingress Controller" \
      maintainer="kubernetes@nginx.com" \
      vendor="NGINX Inc" \
      version="${IC_VERSION#v}" \
      release="1" \
      summary="The Ingress Controller is an application that runs in a cluster and configures an HTTP load balancer according to Ingress resources." \
      description="The Ingress Controller is an application that runs in a cluster and configures an HTTP load balancer according to Ingress resources." \
      io.k8s.description="NGINX Ingress Controller is an application that runs in a cluster and configures an HTTP load balancer according to Ingress resources." \
      io.openshift.tags="nginx,ingress-controller,ingress,controller,kubernetes,openshift" \
      org.opencontainers.image.version="${IC_VERSION#v}" \
      org.opencontainers.image.documentation="https://docs.nginx.com/nginx-ingress-controller" \
      org.opencontainers.image.vendor="NGINX Inc <kubernetes@nginx.com>" \
      org.opencontainers.image.description="NGINX Ingress Controller for Kubernetes" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.title="kubernetes-ingress" \
      org.opencontainers.image.source="https://github.com/nginx/kubernetes-ingress" \
      org.opencontainers.image.url="https://github.com/nginx/kubernetes-ingress" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.nginx.kic.image.build.target="linux/ppc64le" \
      org.nginx.kic.image.build.os="ubi" \
      org.nginx.kic.image.build.nginx.version="" \
      io.artifacthub.package.readme-url="https://raw.githubusercontent.com/nginx/kubernetes-ingress/main/README.md" \
      io.artifacthub.package.logo-url="https://docs.nginx.com/nginx-ingress-controller/images/icons/NGINX-Ingress-Controller-product-icon.svg" \
      io.artifacthub.package.maintainers="[{\"name\":\"NGINX Inc\",\"email\":\"kubernetes@nginx.com\"}]" \
      io.artifacthub.package.license="Apache-2.0" \
      io.artifacthub.package.keywords="kubernetes,ingress,nginx,controller"

COPY --from=nginx-src-builder /tmp/kubernetes-ingress/LICENSE /licenses/LICENSE

# Install runtime shared libraries; 
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN microdnf install -y --nodocs \
        shadow-utils libcap \
        pcre2 openssl-libs zlib libxml2 libxslt libjpeg-turbo gd libpng libedit \
    && groupadd --system --gid 101 nginx \
    && useradd  --system --gid nginx --no-create-home \
                --home-dir /nonexistent --comment "nginx user" \
                --shell /bin/false --uid 101 nginx \
    && groupadd --gid 1000 nginx-agent \
    && usermod -aG nginx-agent root \
    && microdnf remove -y shadow-utils \
    && microdnf clean all \
    && rm -rf /var/cache/dnf

COPY --from=nginx-src-builder /usr/sbin/nginx        /usr/sbin/nginx
COPY --from=nginx-src-builder /usr/sbin/nginx-debug  /usr/sbin/nginx-debug

COPY --from=nginx-src-builder /usr/lib64/nginx/modules/ngx_http_js_module.so            /usr/lib64/nginx/modules/
COPY --from=nginx-src-builder /usr/lib64/nginx/modules/ngx_stream_js_module.so          /usr/lib64/nginx/modules/
COPY --from=nginx-src-builder /usr/lib64/nginx/modules/ngx_http_xslt_filter_module.so   /usr/lib64/nginx/modules/
COPY --from=nginx-src-builder /usr/lib64/nginx/modules/ngx_http_image_filter_module.so  /usr/lib64/nginx/modules/
COPY --from=nginx-src-builder /usr/lib64/nginx/modules/ngx_otel_module.so               /usr/lib64/nginx/modules/
COPY --from=nginx-src-builder /usr/lib64/nginx/modules/ngx_http_acme_module.so          /usr/lib64/nginx/modules/


COPY --from=nginx-src-builder /usr/local/lib64/libcares.so.2  /usr/lib64/
COPY --from=nginx-src-builder /usr/local/lib64/libcares.so    /usr/lib64/

COPY --from=nginx-src-builder /etc/nginx            /etc/nginx
COPY --from=nginx-src-builder --chmod=0775 /usr/bin/nginx-agent  /usr/bin/nginx-agent
COPY --from=nginx-src-builder /usr/bin/njs  /usr/bin/njs

RUN /usr/bin/nginx-agent --version


RUN mkdir -p \
        /var/cache/nginx \
        /var/log/nginx \
        /var/run \
        /etc/nginx-agent \
        /run/nginx-agent \
        /var/lib/nginx-agent \
        /var/log/nginx-agent \
    && chown root:nginx-agent /run/nginx-agent /var/lib/nginx-agent /var/log/nginx-agent \
    && chmod 755 /run/nginx-agent /var/lib/nginx-agent /var/log/nginx-agent \
    && chown 101:0 /licenses /licenses/LICENSE \
    && chmod 755 /licenses \
    && chmod 664 /licenses/LICENSE \
    && ln -sfn ../../usr/lib64/nginx/modules /etc/nginx/modules \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log


COPY --from=nginx-src-builder --chown=101:0 --chmod=0640 /etc/nginx-agent/nginx-agent.conf /etc/nginx-agent/nginx-agent.conf
RUN chown 101:0 /etc/nginx-agent

# -----------------------------------------------------------------------------
# Stage 3: common — IC directories, setcap, config templates
# -----------------------------------------------------------------------------
FROM ubi AS common

ARG IC_VERSION
ARG BUILD_OS=ubi

ENV BUILD_OS=${BUILD_OS}

COPY --from=nginx-src-builder /tmp/kubernetes-ingress/internal/configs/njs/                               /etc/nginx/njs/
COPY --from=nginx-src-builder /tmp/kubernetes-ingress/internal/configs/version1/nginx.ingress.tmpl         /
COPY --from=nginx-src-builder /tmp/kubernetes-ingress/internal/configs/version1/nginx.tmpl                 /
COPY --from=nginx-src-builder /tmp/kubernetes-ingress/internal/configs/version2/nginx.virtualserver.tmpl   /
COPY --from=nginx-src-builder /tmp/kubernetes-ingress/internal/configs/version2/nginx.transportserver.tmpl /

RUN mkdir -p \
        /var/lib/nginx \
        /etc/nginx/secrets \
        /etc/nginx/stream-conf.d \
        /etc/nginx/conf.d \
        /usr/share/nginx \
    && mv /etc/nginx/html /usr/share/nginx/html \
    && setcap 'cap_net_bind_service=+eip' /usr/sbin/nginx \
    && setcap 'cap_net_bind_service=+eip' /usr/sbin/nginx-debug \
    && setcap -v 'cap_net_bind_service=+eip' /usr/sbin/nginx \
    && setcap -v 'cap_net_bind_service=+eip' /usr/sbin/nginx-debug \
    && chown -R 101:0 \
         /etc/nginx \
         /var/cache/nginx \
         /var/lib/nginx \
         /var/log/nginx \
         /*.tmpl \
    && chmod -R g=u \
         /etc/nginx \
         /var/cache/nginx \
         /var/lib/nginx \
         /var/log/nginx \
         /*.tmpl \
    && chown -h 0:0 /var/log/nginx/access.log /var/log/nginx/error.log \
    && rm -f /etc/nginx/conf.d/*

# -----------------------------------------------------------------------------
# Stage 4: local — default build target
# -----------------------------------------------------------------------------
FROM common AS local

ARG BUILD_OS=ubi
ENV BUILD_OS=${BUILD_OS}

LABEL org.nginx.kic.image.build.version="local"

COPY --from=nginx-src-builder --chown=101:0 --chmod=0775 /usr/bin/nginx-ingress /nginx-ingress

USER 0
RUN setcap  'cap_net_bind_service=+ep' /nginx-ingress \
    && setcap -v 'cap_net_bind_service=+ep' /nginx-ingress
USER 101

EXPOSE 80 443
STOPSIGNAL SIGTERM
ENTRYPOINT ["/nginx-ingress"]
