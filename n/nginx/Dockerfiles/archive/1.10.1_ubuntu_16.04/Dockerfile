FROM ppc64le/ubuntu:xenial

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV LATEST_STABLE_VERSION="1.10.1"
# Install dependencies needed for building nginx 1.10.1 from source
RUN apt-get update

RUN apt-get install -y \
        build-essential \
        libpcre3-dev \
        libssl-dev \
        zlib1g-dev \
        git-core

# Clone the git repo
RUN git clone https://github.com/nginx/nginx --branch=release-$LATEST_STABLE_VERSION \
        # Congfigures the build,generates make files and build it
        && cd nginx/ \
        && ./auto/configure \
        && make \
        && make install \
        && make clean \
        && rm -rf /nginx

# Expose the default port
EXPOSE 80 443

# Setting environment path
ENV PATH=$PATH:/usr/local/nginx/sbin/

# Running the nginx inside the container
CMD ["nginx","-g", "daemon off;"]

