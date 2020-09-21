FROM registry.access.redhat.com/ubi8/ubi-minimal:latest AS builder

MAINTAINER "Priya Seth<sethp@us.ibm.com>"

# Install prerequisite
RUN microdnf install -y automake make cmake autoconf libtool wget git m4 libgomp gcc gcc-c++ which python2 wget

# Install PEG manually
RUN wget https://www.piumarta.com/software/peg/peg-0.1.18.tar.gz;\
    tar xzf peg-0.1.18.tar.gz;\
    cd peg-0.1.18;\
    make; make install

# Clone RedisGraph
RUN cd /
RUN git clone --recurse-submodules https://github.com/RedisGraph/RedisGraph.git

WORKDIR /RedisGraph

# Build RedisGraph
RUN git checkout v2.0.20 && \
    ln /usr/bin/python2 /usr/bin/python && \
    make clean && \
    make

# Build redis
WORKDIR /
RUN wget http://download.redis.io/releases/redis-5.0.8.tar.gz;\
    tar xzf redis-5.0.8.tar.gz;\
    cd redis-5.0.8;\
    make

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

ENV LIBDIR /usr/lib/redis/modules

# Install prerequisite
RUN microdnf install -y libgomp

# Copy redis over from builder
COPY --from=builder /redis-5.0.8/src/redis-server /usr/bin

# Copy redisgraph.so over from builder
RUN mkdir -p "$LIBDIR"
COPY --from=builder /RedisGraph/src/redisgraph.so "$LIBDIR"

# Run redis with RedisGraph
EXPOSE 6379
CMD ["redis-server", "--protected-mode no", "--loadmodule", "/usr/lib/redis/modules/redisgraph.so"]

