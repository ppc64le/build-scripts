FROM adoptopenjdk/openjdk8-openj9:ubi

RUN dnf install -y gcc gcc-c++ cmake make git curl

RUN curl -o /usr/local/bin/bazel https://oplab9.parqtec.unicamp.br/pub/ppc64el/bazel/ubuntu_18.04/bazel_bin_ppc64le_4.0.0 && \
  chmod 755 /usr/local/bin/bazel

CMD [bash]
