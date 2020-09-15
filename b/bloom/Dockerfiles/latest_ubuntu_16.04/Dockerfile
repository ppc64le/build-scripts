FROM ppc64le/ubuntu:16.04

RUN apt-get update && \
        apt-get install -y git make build-essential && \
        git clone https://github.com/ArashPartow/bloom bloom && cd bloom && make && \
        ./bloom_filter_example01 && ./bloom_filter_example02 && ./bloom_filter_example03 && \
        apt-get purge -y git make build-essential && apt-get autoremove -y

CMD ["/bin/bash"]
