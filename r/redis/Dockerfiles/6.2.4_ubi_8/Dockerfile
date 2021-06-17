FROM registry.access.redhat.com/ubi8/ubi:latest

# Required Labels
LABEL name="redis" \
      maintainer="Sneha.Kanekar1@ibm.com" \
      vendor="Redis Labs" \
      version="6.2.4" \
      release="1" \
      summary="Red Hat UBI Redis" \
      description="Red Hat UBI Redis Application"

RUN yum update -y -q && yum install -y -q sudo \
  && useradd --create-home --home-dir /home/redis --shell /bin/bash --system --user-group redis \
  && echo '%redis ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER redis
WORKDIR /home/redis

RUN sudo yum update -y -q \
  && sudo yum install -y -q make gcc git \
  && git clone https://github.com/redis/redis.git && \
  pushd redis && \
  git checkout 6.2.4 && \
  make distclean && \
  make V=1 && \
  sudo make install && \
  popd && \
  rm -fr redis && \
  sudo yum remove -y make gcc git

# Creating volume directory so we can share data between container and host
VOLUME /data

# Exposing port at out side world.i
EXPOSE 6379

# Started redis server as a default command.
CMD ["redis-server"]
