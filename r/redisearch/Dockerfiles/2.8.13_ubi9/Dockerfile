FROM registry.access.redhat.com/ubi9/ubi:9.3 as builder

ENV PACKAGE_VERSION=v2.8.13

RUN yum install -y https://dl.fedoraproject.org/pub/epel/9/Everything/ppc64le/Packages/e/epel-release-9-7.el9.noarch.rpm && \
        yum install -y wget git gcc gcc-c++ make cmake libstdc++-static python3.11 python3.11-devel python3.11-pip gtest gtest-devel python3-psutil

RUN git clone --recursive https://github.com/RediSearch/RediSearch.git && \
    cd RediSearch && \
    git checkout $PACKAGE_VERSION && \
    cd .install/ && \
    ./install_boost.sh 1.83.0 && cd .. && \
    make fetch && \
    make build TEST=1 && \
    sed -i "s/\(.*\)'Development Tools'\(.*\)/#\1'Development Tools'\2/g" deps/readies/bin/getredis && \
    ./deps/readies/bin/getredis

# Build redis
FROM registry.access.redhat.com/ubi9/ubi

ENV LIBDIR /usr/lib/redis/modules

# Copy redis over from builder
COPY --from=builder /usr/local/bin/redis-server /usr/bin

# Sanity test
RUN redis-server --version

WORKDIR /data

# Copy redisearch.so over from builder
RUN mkdir -p "$LIBDIR"
COPY --from=builder /RediSearch/bin/linux-ppc64le-release/search/redisearch.so  "$LIBDIR"

# Run redis with RediSearch
EXPOSE 6379
CMD ["redis-server", "--loadmodule", "/usr/lib/redis/modules/redisearch.so"]
