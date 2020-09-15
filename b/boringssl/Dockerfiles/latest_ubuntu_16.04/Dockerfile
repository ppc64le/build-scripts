FROM golang:1.10
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && apt-get install -y cmake && \
  git clone https://boringssl.googlesource.com/boringssl && \
  cd boringssl && mkdir build && cd build && \
  cmake -DCMAKE_BUILD_TYPE=Release .. && make && \
  make all_tests && make run_tests && \
  apt-get remove -y cmake && apt-get autoremove -y

CMD [ "/bin/bash" ]


