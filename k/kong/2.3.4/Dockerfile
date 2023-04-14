FROM registry.access.redhat.com/ubi7/ubi AS build

WORKDIR /root

ENV VERSION=2.3.4
ENV HOME=/root
ENV OPENSSL_DIR=/usr/local/openssl
ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=$HOME/kong/bin:/usr/local/openresty/bin:/usr/local/openresty/nginx/sbin:/usr/local/luarocks/bin:$PATH

RUN yum -y install libtool zlib zlib-devel unzip zip make wget git patch make gcc-c++ ncurses-devel

RUN git clone https://github.com/yaml/libyaml.git \
    && cd libyaml \
    && git checkout tags/0.1.4 \
    && ./bootstrap && ./configure && make && make install;

RUN wget ftp://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz \
    && tar -xzf readline-7.0.tar.gz \
    && cd readline-7.0 \
    && ./configure \
    && make \
    && make install \
    && cd .. ;

RUN wget https://www.lua.org/ftp/lua-5.1.5.tar.gz \
    && tar -xzvf lua-5.1.5.tar.gz \
    && cd  lua-5.1.5 \
    && make linux \
    && cd .. ;

RUN git clone https://github.com/kong/openresty-build-tools \
    && cd openresty-build-tools \
    && lineNum=$(grep -n "tar -xzvf openresty-\$OPENRESTY_VER.tar.gz" kong-ngx-build | tr -s " " " " |cut -d: -f 1) \
    && lineNum=`expr $lineNum + 1` \
    && sed -i  -e ''$lineNum'icd -' kong-ngx-build \
    && sed -i  -e ''$lineNum'igit checkout 2763a421d6219c8cb2bbd39246de619dc796bab6' kong-ngx-build \
    && sed -i  -e ''$lineNum'icd openresty-${OPENRESTY_VER}/bundle/LuaJIT-2.1-20190507' kong-ngx-build \
    && sed -i  -e ''$lineNum'igit clone https://github.com/openresty/luajit2.git openresty-${OPENRESTY_VER}/bundle/LuaJIT-2.1-20190507' kong-ngx-build \
    && sed -i  -e ''$lineNum'imkdir openresty-${OPENRESTY_VER}/bundle/LuaJIT-2.1-20190507' kong-ngx-build \
    && sed -i  -e ''$lineNum'irm -rf openresty-${OPENRESTY_VER}/bundle/LuaJIT-*/' kong-ngx-build \
    && sed -i 's/OPENRESTY_OPTS+=('"'"'--with-pcre=$PCRE_DOWNLOAD'"'"')/OPENRESTY_OPTS+=('"'"'--with-pcre=$PCRE_DOWNLOAD --with-luajit-xcflags="-DLUAJIT_ENABLE_GC64" '"'"')/' kong-ngx-build \
    && sed -i 's/ftp.pcre.org/ftp.exim.org/' kong-ngx-build \
    && ./kong-ngx-build -p /usr/local/ --no-openresty-patches --openresty 1.17.8.2 --openssl 1.1.1d --luarocks 3.2.1 --pcre 8.43;

RUN git clone https://github.com/Kong/kong \
    && cd kong \
    && git checkout $VERSION \
    && git config --global url."https://github".insteadOf git://github \
    && luarocks make OPENSSL_DIR=/usr/local/openssl


FROM registry.access.redhat.com/ubi7/ubi AS run
ENV VERSION=2.3.4
ENV HOME=/root
ENV OPENSSL_DIR=/usr/local/openssl
ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PATH=$HOME/kong/bin:/usr/local/openresty/bin:/usr/local/openresty/nginx/sbin:/usr/local/luarocks/bin:$PATH
RUN yum install -y libtool zlib zlib-devel perl ncurses-devel && yum clean all
COPY --from=build /usr/local/luarocks /usr/local/luarocks
COPY --from=build /usr/local/openresty /usr/local/openresty
COPY --from=build /usr/local/openssl /usr/local/openssl
RUN ln -s /usr/local/luarocks/share/lua /usr/local/share/lua && ln -s /usr/local/luarocks/lib/lua /usr/local/lib/lua
COPY --from=build /root/kong/bin/* /bin/
RUN kong start || echo
STOPSIGNAL SIGQUIT

CMD ["kong", "docker-start"]
