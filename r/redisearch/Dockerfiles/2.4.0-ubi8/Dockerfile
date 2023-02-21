FROM registry.access.redhat.com/ubi8/ubi:8.5 as builder

ENV REDISEARCH_VERSION=v2.4.0

RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm; \
        yum update -y; \
        yum install -y wget git gcc gcc-c++ make python38 cmake  python3-devel libstdc++-static;

RUN ln -s /usr/bin/python3 /usr/bin/python \
    && git clone --recursive https://github.com/RediSearch/RediSearch.git \
    && cd RediSearch \
    && git checkout ${REDISEARCH_VERSION} \
    && make fetch \
    && make build 

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

