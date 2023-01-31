FROM registry.access.redhat.com/ubi8/ubi:8.5 as builder

RUN yum install -y patch bzip2 git make gcc-c++ python2-devel openssl-devel libcurl-devel wget python2 m4 ncurses-devel libicu-devel python36 python3-devel protobuf-c

RUN curl -O https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf install -y epel-release-latest-8.noarch.rpm && \
    rm -f epel-release-latest-8.noarch.rpm

RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh| bash && \
    source ~/.nvm/nvm.sh && \
    nvm install stable && \
    nvm use stable

RUN ln -s /usr/bin/python2 /usr/bin/python && \
   git clone https://github.com/rethinkdb/rethinkdb.git && \
    cd rethinkdb && \
    git checkout v2.4.x && \
    ./configure --allow-fetch && \
    make -j4 && \
    make install

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

COPY --from=builder /rethinkdb/build/release/rethinkdb /usr/bin

VOLUME ["/data"]

WORKDIR /data

CMD ["rethinkdb", "--bind", "all"]

#   process cluster webui
EXPOSE 28015 29015 8080

