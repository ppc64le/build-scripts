FROM registry.access.redhat.com/ubi8/ubi:8.5 as builder

ENV REDISEARCH_VERSION=v2.4.16

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm; \
        yum update -y; \
        yum install -y wget git gcc gcc-c++ make python38 cmake python38-devel libstdc++-static;
#       yum install -y python3-psutil;

RUN ln -s /usr/bin/python3 /usr/bin/python \
    && git clone --recursive https://github.com/RediSearch/RediSearch.git \
    && cd RediSearch \
    && git checkout ${REDISEARCH_VERSION} \
    && pip3 install --upgrade pip \
    && python3 -m pip install --no-cache-dir git+https://github.com/RedisLabsModules/RLTest.git@master \
    && python3 -m pip install --no-cache-dir git+https://github.com/Grokzen/redis-py-cluster.git@master \
    && python3 -m pip install --no-cache-dir git+https://github.com/RedisLabs/RAMP@master \
    && make fetch \
    && make build \
    && sed -i "s/\(.*\)'Development Tools'\(.*\)/#\1'Development Tools'\2/g" deps/readies/bin/getredis \
    && ./deps/readies/bin/getredis

# Build redis
FROM registry.access.redhat.com/ubi8/ubi

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

