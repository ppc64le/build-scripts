FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>"

ARG PACKAGE_VERSION=release-1.25.3

RUN yum install git gcc gcc-c++ pcre-devel zlib-devel which rpm rpm-build make -y

# Clone the git repo
RUN git clone https://github.com/nginx/nginx \
        && cd nginx/ \
        && git checkout $PACKAGE_VERSION \
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

