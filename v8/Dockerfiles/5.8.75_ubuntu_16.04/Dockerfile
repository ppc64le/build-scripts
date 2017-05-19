FROM ppc64le/ubuntu:16.04
MAINTAINER Yugandha Deshpande <yugandha@us.ibm.com>

USER root
RUN apt-get update && apt-get install -y \
  git \
  build-essential \
  python-dev \
  libreadline-dev && \
  rm -rf /var/lib/apt/lists/*
RUN groupadd -r nonroot && \
  useradd -r -g nonroot -d /home/nonroot -s /sbin/nologin -c "Nonroot User" nonroot && \
  mkdir /home/nonroot && \
  chown -R nonroot:nonroot /home/nonroot

USER nonroot
WORKDIR /home/nonroot

RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git

ENV PATH ./depot_tools:$PATH
ENV GYP_CHROMIUM_NO_ACTION 0

RUN fetch v8 && \
    cd v8 && \
    git checkout 5.8.75 && \
    make ppc64.release console=readline snapshot=off werror=no

USER root
RUN mv v8/out/ppc64.release/d8 /usr/local/bin && \
    chown root:root /usr/local/bin/d8 && \
    ln -s /usr/local/bin/d8 /usr/local/bin/v8 && \
    rm -rf v8  depot_tools

USER nonroot

CMD ["d8"]
