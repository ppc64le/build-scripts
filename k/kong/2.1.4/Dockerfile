FROM registry.access.redhat.com/ubi7/ubi

WORKDIR /root

ENV VERSION=2.1.4
ENV HOME=/root
ENV OPENSSL_DIR=$HOME/openresty-build-tools/build/openssl
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV PATH=$HOME/openresty-build-tools/build/openresty/bin:$HOME/openresty-build-tools/build/openresty/nginx/sbin:$HOME/openresty-build-tools/build/luarocks/bin:$PATH

RUN yum -y install libtool zlib zlib-devel unzip zip make lua-devel wget git patch make gcc-c++ ncurses-devel; \
    wget https://www.rpmfind.net/linux/epel/7/ppc64le/Packages/l/luarocks-2.3.0-1.el7.ppc64le.rpm \
    && rpm -i luarocks-2.3.0-1.el7.ppc64le.rpm; 

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
    && ./kong-ngx-build -p build --no-openresty-patches --openresty 1.15.8.2 --openssl 1.1.1d --luarocks 3.2.1 --pcre 8.43;

RUN git clone https://github.com/Kong/kong \
    && cd kong \
    && git checkout $VERSION \
    && luarocks make OPENSSL_DIR=/root/openresty-build-tools/build/openssl \
    && lineNum=$(grep -n grpcurl: Makefile | cut -d: -f 1) \
    && begin=`expr $lineNum + 1` && end=`expr $lineNum + 3` \
    && sed -i -e ''$begin,$end'd' Makefile \
    && make dev \
    && ulimit -n 65536 \
    && eval $(luarocks path --bin) \
    && make test;


STOPSIGNAL SIGQUIT

CMD ["kong", "docker-start"]
