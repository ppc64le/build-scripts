FROM ppc64le/ubuntu:latest
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends pypy && \
    rm -rf /var/lib/apt/lists/*

CMD ["pypy"]
