FROM ubuntu:16.04
MAINTAINER Meghali Dhoble <dhoblem@us.ibm.com>

RUN apt-get update && apt-get install -y git make mkisofs parted asciidoc && \
    git clone http://github.com/rear/rear  && \
    cd rear/  && git checkout rear-2.4 && \
    make && make install && cd ../ && rm -rf /rear && \
    apt-get purge -y git make mkisofs parted asciidoc && \
    apt-get autoremove -y

CMD rear -V

