FROM ubuntu:18.04

# Owner information
MAINTAINER "Amitkumar Ghatwal <ghatwala@us.ibm.com>"

ENV GOROOT=/usr/lib/go-1.10
ENV PATH=$GOROOT/bin:$PATH

ENV PATH=/node-v9.9.0-linux-ppc64le/bin:$PATH

RUN apt-get update && apt-get install -y make curl tar wget git unzip build-essential libexpat-dev libcurl4-openssl-dev zlib1g-dev python cargo golang-1.10-go \
    && wget https://nodejs.org/dist/v9.9.0/node-v9.9.0-linux-ppc64le.tar.gz && tar -xzf node-v9.9.0-linux-ppc64le.tar.gz \
    && npm install -g yarn \
    && wget https://static.rust-lang.org/dist/rust-1.28.0-powerpc64le-unknown-linux-gnu.tar.gz \
    && tar -xzf rust-1.28.0-powerpc64le-unknown-linux-gnu.tar.gz \
    && cd rust-1.28.0-powerpc64le-unknown-linux-gnu \
    && ./install.sh \
    && cargo install ripgrep \
    && cd / \
    && git clone https://github.com/theia-ide/theia \
    && cd theia && yarn --skip-integrity-check;exit 0
RUN cp -a /root/.cargo/bin /theia/node_modules/vscode-ripgrep/ \
    && cd /theia && yarn run build \
    && cd / \
    && git clone https://github.com/desktop/dugite-native.git \
    && cd dugite-native/ \
    && git checkout v2.17.0 \
    && cp ./script/build-arm64.sh ./script/build-ppc64le.sh \
    && git submodule update --init --recursive

COPY build-ppc64le.patch /dugite-native/script
RUN  cd /dugite-native/script && patch build-ppc64le.sh < build-ppc64le.patch \
     && sed -i -e '/exit 1/ c\  bash "$DIR/build-ppc64le.sh" $SOURCE $DESTINATION $BASEDIR' build.sh \
     && sed -i -e '/exit 1/ c\  GZIP_FILE="dugite-native-$VERSION-ppc64le.tar.gz"\n\  LZMA_FILE="dugite-native-$VERSION-ppc64le.lzma"' package.sh \
     && cd /dugite-native \
     && bash ./script/build.sh \
     && bash ./script/package.sh \
     && rm -rf /theia/node_modules/dugite/git/* \
     && cp /dugite-native/output/dugite-native-v2.17.0-ppc64le.tar.gz /theia/node_modules/dugite/git \
     && cd /theia/node_modules/dugite/git \
     && tar -xzf dugite-native-v2.17.0-ppc64le.tar.gz \
     && rm -rf /dugite-native /node-v9.9.0-linux-ppc64le.tar.gz \
     && apt-get purge -y make git wget unzip libexpat-dev cargo python golang-1.10-go && apt-get autoremove -y \
     && rm -rf $HOME/rust-1.28.0-powerpc64le-unknown-linux-gnu.tar.gz  $HOME/node-v9.9.0-linux-ppc64le.tar.gz


EXPOSE 3000
WORKDIR /theia/examples/browser
ENV SHELL /bin/bash
CMD yarn run start --hostname 0.0.0.0

