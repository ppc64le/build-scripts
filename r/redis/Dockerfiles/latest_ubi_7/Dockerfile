FROM registry.access.redhat.com/ubi7/ubi:latest

# Required Labels
LABEL name="redis" \
      maintainer="redmark@us.ibm.com" \
      vendor="Redis Labs" \
      version="3.2.13" \
      release="1" \
      summary="Red Hat UBI Redis" \
      description="Red Hat UBI Redis Application"

COPY licenses /licenses

RUN yum update -y -q && yum install -y -q sudo \
  && useradd --create-home --home-dir /home/redis --shell /bin/bash --system --user-group redis \
  && echo '%redis ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER redis
WORKDIR /home/redis

RUN sudo yum update -y -q \
  && sudo yum install -y -q make gcc git tcl \
  && git clone https://github.com/antirez/redis.git && \
  pushd redis && \
  git checkout 3.2.13 && \
  make distclean && \
  make V=1 MALLOC=libc && \
  sudo make install && \
  popd && \
  rm -fr redis && \
  sudo yum remove -y make gcc git

# Creating volume directory so we can share data between container and host
VOLUME /data

# Exposing port at out side world.
EXPOSE 6379

# Started redis server as a default command.
CMD ["redis-server"]
