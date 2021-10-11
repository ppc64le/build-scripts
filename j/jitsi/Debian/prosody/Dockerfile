ARG JITSI_REPO=jitsi

FROM ${JITSI_REPO}/base as builder

RUN \
    apt-dpkg-wrap apt-get update \
    && apt-dpkg-wrap apt-get install -y \
      lua5.2 \
      liblua5.2-dev \
      libsasl2-dev \
      libssl-dev \
      luarocks \
      git \
      gcc \
      g++ \
      cmake \
      make \
      pkg-config \
      m4 \
      autoconf \
      file \
    && luarocks install cyrussasl 1.1.0-1 \
    && luarocks install lua-cjson 2.1.0-1 \
    && git clone https://github.com/starius/luacrypto && cd luacrypto \
    && wget -O config.guess 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' \
    && wget -O config.sub 'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD' \
    && export LUA_LIBS="-L/usr/lib/powerpc64le-linux-gnu -llua" \
    && export LUA_CFLAGS="-I/usr/include" \
    && ./configure && make && make install \
    && luarocks install luajwtjitsi 1.3-7 \
    && luarocks install net-url 0.9-1

FROM ${JITSI_REPO}/base

ADD https://prosody.im/files/prosody-debian-packages.key /tmp/prosody.key

RUN \
    apt-key add /tmp/prosody.key \
    && rm -f /tmp/prosody.key \
    && echo "deb http://packages.prosody.im/debian buster main" > /etc/apt/sources.list.d/prosody.list \
    && apt-dpkg-wrap apt-get update \
    && apt-dpkg-wrap apt-get install -y \
      prosody \
      libssl1.1 \
      sasl2-bin \
      libsasl2-modules-ldap \
      lua-basexx \
      patch \
    && apt-dpkg-wrap apt-get install -t buster-backports -y \
      lua-ldap \
      lua-sec \
    && apt-cleanup \
    && rm -rf /etc/prosody

RUN \
    apt-dpkg-wrap apt-get update \
    && apt-dpkg-wrap apt-get install -y nodejs npm git make gcc g++ \
    && git clone https://github.com/jitsi/jitsi-meet && cd jitsi-meet \
    && npm install && make \
    && mv resources/prosody-plugins /prosody-plugins \
    && apt-dpkg-wrap apt-get -y purge git make gcc g++ \
    && apt-cleanup \
    && rm -rf /tmp/pkg /var/cache/apt

RUN patch -d /usr/lib/prosody/modules/muc -p0 < /prosody-plugins/muc_owner_allow_kick.patch

COPY rootfs/ /

COPY --from=builder /usr/local/lib/lua /usr/local/lib/lua
COPY --from=builder /usr/local/share/lua /usr/local/share/lua

EXPOSE 5222 5347 5280

VOLUME ["/config", "/prosody-plugins-custom"]
