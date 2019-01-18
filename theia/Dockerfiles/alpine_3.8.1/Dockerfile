FROM ppc64le/node:8.12.0-alpine

# Owner information
MAINTAINER "Amitkumar Ghatwal <ghatwala@us.ibm.com>"

#Set the required env. variables
ENV GOROOT=/usr/lib/go
ENV PATH=$GOROOT/bin:$PATH

#install yarn
RUN apk --update add --no-cache git zlib-dev curl curl-dev expat expat-dev file go go-tools xz perl-utils \
    && npm install -g yarn &&  mkdir /root/test262 && cd /root/test262 \
    && git clone https://github.com/mksully22/ppc64le_alpine_rust_1.26.2.git \
    && cp ./ppc64le_alpine_rust_1.26.2/* . \
    && sed -i '/apk add alpine-sdk/c\apk add alpine-sdk gcc llvm-libunwind-dev cmake file libffi-dev llvm5-dev llvm5-test-utils python2 tar zlib-dev gcc llvm-libunwind-dev musl-dev util-linux bash' build_rust262.sh \
    && sed -i ':a;N;$!ba; s/fetch_rust/fetch_rust || true/2' build_rust262.sh \
    && sed -i ':a;N;$!ba; s/apply_patches/apply_patches || true/2' build_rust262.sh \
    && sed -i ':a;N;$!ba; s/mk_rustc/mk_rustc || true/2' build_rust262.sh \
    && ./build_rust262.sh \
    && cd / && git clone https://github.com/BurntSushi/ripgrep \
    && cd ripgrep/ \
    && cargo build --release \
    && cd / && git clone https://github.com/theia-ide/theia && cd theia && git checkout v0.3.15\
    && yarn --skip-integrity-check;exit 0

RUN cp -a /ripgrep/target/release /theia/node_modules/vscode-ripgrep/ \
    && cd /theia && yarn run build \
    && cd / &&  git clone https://github.com/desktop/dugite-native.git && cd /dugite-native/ \
    && git checkout v2.17.0 \
    && cp ./script/build-arm64.sh ./script/build-ppc64le.sh \
    && git submodule update --init --recursive

COPY build-ppc64le.patch /dugite-native/script

RUN  cd /dugite-native/script && patch build-ppc64le.sh < build-ppc64le.patch \
     && sed -i -e '/exit 1/ c\  bash "$DIR/build-ppc64le.sh" $SOURCE $DESTINATION $BASEDIR' build.sh \
     && sed -i -e '/exit 1/ c\  GZIP_FILE="dugite-native-$VERSION-ppc64le.tar.gz"\n\  LZMA_FILE="dugite-native-$VERSION-ppc64le.lzma"' package.sh \
     && sed -i '/#define REG_ENOSYS      -1/ i #define REG_STARTEND    00004' /usr/include/regex.h \
     && cd /dugite-native \
     && bash ./script/build.sh \
     && bash ./script/package.sh \
     && rm -rf /theia/node_modules/dugite/git/* \
     && cp /dugite-native/output/dugite-native-v2.17.0-ppc64le.tar.gz /theia/node_modules/dugite/git \
     && cd /theia/node_modules/dugite/git \
     && tar -xzf dugite-native-v2.17.0-ppc64le.tar.gz \
     && rm -rf /dugite-native /root/test262 /tmp/* /root/* /root/.cargo /home/rustbuild262/* /ripgrep \
     && apk del alpine-sdk curl git expat-dev ca-certificates libcurl curl-dev cmake  go go-tools libcurl file perl-utils xz-libs xz tar bash libarchive cmake llvm-libunwind llvm-libunwind-dev llvm5-libs llvm5 llvm5-dev gdbm sqlite-libs llvm5-test-utils rust-stdlib rust cargo libgit2 expat zlib-dev libcurl python2 libffi-dev scanelf libc-utils pkgconf binutils gmp isl libgomp gcc

EXPOSE 3000
WORKDIR /theia/examples/browser
ENV SHELL /bin/sh
CMD yarn run start --hostname 0.0.0.0

