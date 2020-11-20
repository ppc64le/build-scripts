FROM ppc64le/ubuntu:16.04
MAINTAINER "Snehlata Mohite <smohite@us.ibm.com>"

RUN apt-get update -y\
    &&  apt-get install -y git cmake libdwarf-dev libelf-dev llvm-dev ncurses-dev re2c perl g++ make zlib1g-dev libedit-dev \
    &&  apt-get install -y python-dev llvm-3.6-dev\
    &&  git clone https://github.com/numba/libHLC\
    &&  git clone https://github.com/HSAFoundation/HSAIL-Tools.git\
    &&  cd /HSAIL-Tools/ && mkdir -p build/lnx64 && cd build/lnx64 &&  cmake ../..  && make -j  && make install\
    &&  cd / &&  git clone https://github.com/HSAFoundation/HLC-HSAIL-Development-LLVM\
    &&  mkdir test_llvm\
    &&  cd /test_llvm/ && cmake /HLC-HSAIL-Development-LLVM/ -DLLVM_ENABLE_EH=ON -DLLVM_ENABLE_RTTI=ON  -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=HSAIL\
    &&  cd /test_llvm/ &&  make -j4 && make install && cp /test_llvm/lib/libLLVMHSAILUtil.a /usr/local/lib/\
    &&  cd /libHLC/ &&  LLVMCONFIG=/usr/lib/llvm-3.6/bin/llvm-config make\
    &&  cp /libHLC/libHLC.so /usr/local/lib/\
    &&  apt-get autoremove -y git cmake libdwarf-dev libelf-dev llvm-dev ncurses-dev zlib1g-dev libedit-dev

