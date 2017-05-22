FROM ppc64le/ubuntu:16.04
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV LD_LIBRARY_PATH=/usr/lib:/usr/local/lib:${LD_LIBRARY_PATH}

RUN apt-get update -y && \
    apt-get install -y git libtool pkg-config build-essential \
        autoconf automake gettext && \
    cd /tmp && git clone https://github.com/jedisct1/libsodium.git && \
      cd libsodium && ./autogen.sh && ./configure && make && \
      make install && \
    cd /tmp && git clone https://github.com/zeromq/zeromq4-1.git && \
      cd zeromq4-1 && ./autogen.sh && ./configure && make && \
      make install && \
    rm -rf /tmp/libsodium /tmp/zeromq4-1 && \
    apt-get remove -y --purge git libtool pkg-config build-essential \
        autoconf automake gettext && \
    apt-get autoremove -y

CMD bash
