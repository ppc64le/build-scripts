FROM ppc64le/ubuntu:16.04

RUN apt-get update && \
        apt-get install -y git make build-essential && \
        git clone https://github.com/FFmpeg/FFmpeg && cd FFmpeg && ./configure && make && \
        make check && make install && \
        apt-get purge -y git make build-essential && apt-get autoremove -y

ENTRYPOINT ["/usr/local/bin/ffmpeg"]

