# This Dockerfile has been adopted from the original work
# @ https://github.com/RediSearch/RediSearch/blob/master/docker/Dockerfile

FROM registry.access.redhat.com/ubi8/ubi AS builder

MAINTAINER Kandarpa Malipeddi <kandarpa.malipeddi@ibm.com>

ENV REDISEARCH_VERSION=v2.0.0

RUN yum install -y wget git gcc gcc-c++ make python2; \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm; \
    yum update -y; \
    yum install -y python2-psutil;

RUN git clone https://github.com/Kitware/CMake \
    && cd CMake \
    && git checkout v3.11.4 \
    && ./bootstrap && make && make install \
    && cd .. && rm -rf CMake \
    && ln -s /usr/bin/python2 /usr/bin/python \
    && git clone --recursive https://github.com/RediSearch/RediSearch.git \
    && cd RediSearch \
    && git checkout ${REDISEARCH_VERSION} \
    && python -m pip install --no-cache-dir git+https://github.com/RedisLabsModules/RLTest.git@master \
    && python -m pip install --no-cache-dir git+https://github.com/Grokzen/redis-py-cluster.git@master \
    && python -m pip install --no-cache-dir git+https://github.com/RedisLabs/RAMP@master \
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
COPY --from=builder /RediSearch/build/redisearch.so "$LIBDIR"

# Run redis with RediSearch
EXPOSE 6379
CMD ["redis-server", "--loadmodule", "/usr/lib/redis/modules/redisearch.so"]