# NOTE: This is based on the original work at https://github.com/elastic/dockerfiles/

################################################################################
# This Dockerfile was generated from the template at:
#   src/dev/build/tasks/os_packages/docker_generator/templates/Dockerfile
#
# Beginning of multi stage Dockerfile
################################################################################

################################################################################
# Build stage 0 `builder`:
# Extract Kibana artifact
################################################################################
FROM registry.access.redhat.com/ubi8/ubi:latest AS builder

RUN yum install -y gcc gcc-c++ git golang java-11-openjdk-devel make python38 wget unzip zip

# Create Symlink for python3, used by bazel
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install and load NodeJS
RUN wget https://nodejs.org/dist/v16.14.2/node-v16.14.2-linux-ppc64le.tar.gz && \
    tar -xf node-v16.14.2-linux-ppc64le.tar.gz && \
    cp -r node-v16.14.2-linux-ppc64le/{bin,include,lib,share} /usr/ && \
    rm -rf node-v16.14.2-linux-ppc64le* && \
    npm install -g yarn node-gyp @bazel/bazelisk@1.10.1 && \
    # Add ppc64le support in bazelisk.js
    sed -i "/'x64': 'amd64',/a\    'ppc64': 'ppc64'," /usr/lib/node_modules/@bazel/bazelisk/bazelisk.js

RUN mkdir -p bazel/output && cd bazel/output && \
    wget https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_18.04/bazel_bin_ppc64le_4.2.1 && \
    mv bazel_bin_ppc64le_4.2.1 bazel && \
    chmod 755 bazel

ENV USE_BAZEL_VERSION /bazel/output/bazel

# Build Bazelisk from source
RUN wget https://github.com/bazelbuild/bazelisk/archive/refs/tags/v1.10.1.zip && \
    unzip v1.10.1.zip
COPY ./bazelisk_v1.10.1_ppc64le.patch /bazelisk-1.10.1/
RUN cd /bazelisk-1.10.1 && \
    git apply --ignore-whitespace ./bazelisk_v1.10.1_ppc64le.patch && \
    go build && ./bazelisk build --config=release //:bazelisk-linux-ppc64 && \
    cp -r bazel-out/ppc-opt-*/bin/bazelisk-linux_ppc64 /usr/lib/node_modules/@bazel/bazelisk/

# Build re2
RUN git clone -b 1.16.0 https://github.com/uhop/node-re2.git && cd node-re2 && \
    git submodule update --init --recursive && \
    npm install && \
    gzip -c build/Release/re2.node > linux-ppc64-93.gz

# Clone Kibana and Install required NodeJS version using NVM
RUN git clone -b v7.17.2 --depth=1 https://github.com/elastic/kibana.git
COPY ./kibana_v7.17.2_ppc64le.patch /kibana/
RUN cd /kibana && \
    git apply --ignore-whitespace ./kibana_v7.17.2_ppc64le.patch && \
    sha256=`sha256sum /node-re2/linux-ppc64-93.gz | cut -d' ' -f1` && \
    lineno=`grep -n 'url: zFile,' src/dev/build/tasks/patch_native_modules_task.ts | cut -d':' -f1` && \
    sed -i "${lineno}a\ \ \ \ \ \ \ \ sha256: '${sha256}'," src/dev/build/tasks/patch_native_modules_task.ts && \
    mkdir -p .native_modules/re2/ && \
    mv /node-re2/linux-ppc64-93.gz /kibana/.native_modules/re2/linux-ppc64-93.gz && \
    # this is expected to fail, we just need it to rebuild lmdb-store before bootstrapping
    yarn install 2>/dev/null || true

# Bootstrap Kibana

RUN cd /kibana && \
    sed -i "/case 'x64': return '64-bit';/a case 'ppc64': return '64-bit';" node_modules/node-sass/lib/extensions.js  && \
    npm rebuild node-sass && \
    yarn kbn bootstrap 2>/dev/null || true

RUN cd /kibana/node_modules/lmdb-store/ && npm i && \
    cd /kibana  && yarn kbn bootstrap && yarn build

# Installing Kibana
RUN mkdir /usr/share/kibana

WORKDIR /usr/share/kibana

RUN tar -xzf /kibana/target/kibana-7.17.2-SNAPSHOT-linux-ppc64.tar.gz -C /usr/share/kibana --strip-components 1

# Ensure that group permissions are the same as user permissions.
# This will help when relying on GID-0 to run Kibana, rather than UID-1000.
# OpenShift does this, for example.
# REF: https://docs.openshift.org/latest/creating_images/guidelines.html
RUN chmod -R g=u /usr/share/kibana

# Remove build dependencies
RUN yum remove -y gcc gcc-c++ git golang java-11-openjdk-devel python38 wget unzip zip
################################################################################
# Build stage 1 (the actual Kibana image):
#
# Copy kibana from stage 0
# Add entrypoint
################################################################################
FROM registry.access.redhat.com/ubi8/ubi:latest

EXPOSE 5601

RUN for iter in {1..10}; do \
    yum update --setopt=tsflags=nodocs -y && \
    yum install --setopt=tsflags=nodocs -y \
    fontconfig ca-certificates  && \
    yum clean all && \
    exit_code=0 && break || \
    exit_code=$? && echo "yum error: retry $iter in 10s" && sleep 10; \
    done; \
    exit $exit_code

# Add an init process, check the checksum to make sure it's a match
RUN set -e ; \
    TINI_BIN="" ; \
    case "$(arch)" in \
        aarch64) TINI_BIN='tini-arm64' ;; \
        x86_64) TINI_BIN='tini-amd64' ;; \
        ppc64le) TINI_BIN='tini-ppc64le' ;; \
        *) echo >&2 "Unsupported architecture $(arch)" ; exit 1 ;; \
    esac ; \
  TINI_VERSION='v0.19.0' ; \
  curl --retry 8 -S -L -O "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/${TINI_BIN}" ; \
  curl --retry 8 -S -L -O "https://github.com/krallin/tini/releases/download/${TINI_VERSION}/${TINI_BIN}.sha256sum" ; \
  sha256sum -c "${TINI_BIN}.sha256sum" ; \
  rm "${TINI_BIN}.sha256sum" ; \
  mv "${TINI_BIN}" /bin/tini ; \
  chmod +x /bin/tini

RUN mkdir /usr/share/fonts/local
RUN curl -L -o /usr/share/fonts/local/NotoSansCJK-Regular.ttc https://github.com/googlefonts/noto-cjk/raw/NotoSansV2.001/NotoSansCJK-Regular.ttc
RUN echo "5dcd1c336cc9344cb77c03a0cd8982ca8a7dc97d620fd6c9c434e02dcb1ceeb3  /usr/share/fonts/local/NotoSansCJK-Regular.ttc" | sha256sum -c -
RUN fc-cache -v

# Bring in Kibana from the initial stage.
COPY --from=builder --chown=1000:0 /usr/share/kibana /usr/share/kibana
WORKDIR /usr/share/kibana
RUN ln -s /usr/share/kibana /opt/kibana

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/kibana/bin:$PATH

# Set some Kibana configuration defaults.
COPY --chown=1000:0 config/kibana.yml /usr/share/kibana/config/kibana.yml

# Add the launcher/wrapper script. It knows how to interpret environment
# variables and translate them to Kibana CLI options.
COPY bin/kibana-docker /usr/local/bin/
RUN chmod +x /usr/local/bin/kibana-docker

# Ensure gid 0 write permissions for OpenShift.
RUN chmod g+ws /usr/share/kibana && \
    find /usr/share/kibana -gid 0 -and -not -perm /g+w -exec chmod g+w {} \;

# Remove the suid bit everywhere to mitigate "Stack Clash"
RUN find / -xdev -perm -4000 -exec chmod u-s {} +

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 kibana && \
    useradd --uid 1000 --gid 1000 -G 0 \
    --home-dir /usr/share/kibana --no-create-home \
    kibana

LABEL org.label-schema.build-date="2022-03-28T08:38:19.218Z" \
  org.label-schema.license="Elastic License" \
  org.label-schema.name="Kibana" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.url="https://www.elastic.co/products/kibana" \
  org.label-schema.usage="https://www.elastic.co/guide/en/kibana/reference/index.html" \
  org.label-schema.vcs-ref="07cff2b713ccaea7caa78c054848de6cc2ba0331" \
  org.label-schema.vcs-url="https://github.com/elastic/kibana" \
  org.label-schema.vendor="Elastic" \
  org.label-schema.version="7.17.2" \
  org.opencontainers.image.created="2022-03-28T08:38:19.218Z" \
  org.opencontainers.image.documentation="https://www.elastic.co/guide/en/kibana/reference/index.html" \
  org.opencontainers.image.licenses="Elastic License" \
  org.opencontainers.image.revision="07cff2b713ccaea7caa78c054848de6cc2ba0331" \
  org.opencontainers.image.source="https://github.com/elastic/kibana" \
  org.opencontainers.image.title="Kibana" \
  org.opencontainers.image.url="https://www.elastic.co/products/kibana" \
  org.opencontainers.image.vendor="Elastic" \
  org.opencontainers.image.version="7.17.2"

ENTRYPOINT ["/bin/tini", "--"]

CMD ["/usr/local/bin/kibana-docker"]

USER kibana

