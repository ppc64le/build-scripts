FROM ppc64le/ubuntu:16.04
MAINTAINER "Jay Joshi<joshija@us.ibm.com>"

# Install Dependecies
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823 && \
    apt-get update -y && \
    apt-get install -y dirmngr nodejs npm wget python gcc g++ make git && \
    ln -s /usr/bin/nodejs /usr/bin/node && \
    npm install -g grunt grunt-cli bower && \
    # build nvd3
    git clone https://github.com/novus/nvd3.git && \
    cd nvd3 && \
    npm install && \
    grunt production && \
    apt-get purge -y dirmngr wget gcc g++ python make git && \
    apt-get autoremove -y

WORKDIR /nvd3
CMD ["/bin/bash"]
