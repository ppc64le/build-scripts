FROM registry.access.redhat.com/ubi8/ubi-minimal

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV LATEST_STABLE_VERSION="1.17.1"

RUN microdnf install -y \
        make \
	gcc-c++ \
        pcre-devel \
        openssl-devel \
        zlib-devel \
        git

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

