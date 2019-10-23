FROM registry.access.redhat.com/ubi7/ubi:latest

RUN yum update -y \
  && yum install -y make gcc git tcl \
  && git clone https://github.com/antirez/redis.git && \
  pushd redis && \
  git checkout 3.2.13 && \
  make distclean && \
  make V=1 && \
  make install && \
  popd && \
  rm -fr redis && \
  yum remove -y make gcc git

# Creating volume directory so we can share data between container and host
VOLUME /data

# Started redis server as a default command.
CMD ["redis-server"]

# Exposing port at out side world.
EXPOSE 6379
