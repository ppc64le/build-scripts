FROM registry.access.redhat.com/ubi8/ubi:8.5 as builder

RUN yum update -y && \
    yum install which git wget curl tar bzip2 gcc-c++ python36 make -y && \
    curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o n && \
    bash n v16.17.1 

RUN wget https://github.com/ibmsoe/phantomjs/releases/download/2.1.1/phantomjs-2.1.1-linux-ppc64.tar.bz2 && \
    tar -xvf phantomjs-2.1.1-linux-ppc64.tar.bz2 && \
    mv phantomjs-2.1.1-linux-ppc64/bin/phantomjs /usr/bin && \
    rm -rf phantomjs-2.1.1-linux-ppc64.tar.bz2

ARG VERSION=latest
RUN set -eux \
        && if [ ${VERSION} = "latest" ]; then \
                npm install -g --production --remove-dev eslint; \
        else \
                npm install -g --production --remove-dev eslint@^${VERSION}.0.0; \
        fi \
        \
        && /usr/local/lib/node_modules/eslint/bin/eslint.js --version | grep -E '^v?[0-9]+'

RUN set -eux \
        && find /usr/local/lib/node_modules -type d -iname 'test' -prune -exec rm -rf '{}' \; \
        && find /usr/local/lib/node_modules -type d -iname 'tests' -prune -exec rm -rf '{}' \; \
        && find /usr/local/lib/node_modules -type d -iname 'testing' -prune -exec rm -rf '{}' \; \
        && find /usr/local/lib/node_modules -type d -iname '.bin' -prune -exec rm -rf '{}' \; \
        \
        && find /usr/local/lib/node_modules -type f -iname '.*' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname 'LICENSE*' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname 'Makefile*' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.bnf' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.css' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.def' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.flow' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.html' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.info' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.jst' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.lock' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.map' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.markdown' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.md' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.mjs' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.mli' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.png' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.ts' -exec rm {} \; \
        && find /usr/local/lib/node_modules -type f -iname '*.yml' -exec rm {} \;

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

COPY --from=builder /usr/local/lib/node_modules/ /usr/local/lib/node_modules/

COPY --from=builder /usr/local/bin/node  /usr/bin/node

RUN set -eux && \
    ln -sf /usr/local/lib/node_modules/eslint/bin/eslint.js /usr/bin/eslint

WORKDIR /data
ENTRYPOINT ["eslint"]
CMD ["--help"]

