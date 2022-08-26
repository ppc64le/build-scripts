FROM registry.access.redhat.com/ubi8/ubi:latest


ARG PACKAGE_VERSION=v2.1.0-beta3


RUN set -ex \
    \
    && apk -U upgrade \
    && apk add --no-cache \
        libgcc \
    \
    && apk add --no-cache --virtual .build-deps \
        ca-certificates \
        openssl \
        make \
        gcc \
        libc-dev \
    \
    && wget -c https://github.com/openresty/luajit2/archive/v${LUAJIT_VERSION}.tar.gz \
        -O - | tar xzf - \
    \
    && cd luajit2-${LUAJIT_VERSION} \
    && make -j"$(nproc)" \
    && make install INSTALL_INC=/usr/local/include \
    && cd .. \
    && rm -rf luajit2-${LUAJIT_VERSION} \
    && cd /usr/local/bin \
    && ln -sf luajit lua \
    \
    && apk del .build-deps

CMD ["luajit2"]
