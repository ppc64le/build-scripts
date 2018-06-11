FROM python:3
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

RUN apt-get update -y \
  && apt-get install -y git gcc cmake g++ make wget \
  && wget https://cmake.org/files/v3.11/cmake-3.11.3.tar.gz \
  && tar -xzvf cmake-3.11.3.tar.gz \
  && cd cmake-3.11.3 \
  && ./bootstrap \
  && make \
  && make install \
  && cd .. \
  && git clone https://github.com/open-source-parsers/jsoncpp.git \
  && cd jsoncpp \
  && python amalgamate.py \
  && mkdir -p build/debug && cd build/debug \
  && bash -c "cmake -DCMAKE_BUILD_TYPE=debug -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=OFF -DARCHIVE_INSTALL_DIR=. -G \"Unix Makefiles\" ../.." \
  && apt-get purge --auto-remove git wget -y \ 
  && make \
  && make install

CMD ["/bin/bash"]
